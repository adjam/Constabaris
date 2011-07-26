# -*- coding: utf-8 -*-
# coding=utf-8
# vim: set fileencoding=utf-8 :

from django.http import HttpResponse,Http404, HttpResponseForbidden,HttpResponseRedirect
from django.template import RequestContext
from django.core.urlresolvers import reverse
from django.shortcuts import get_object_or_404
from django.shortcuts import redirect
from django.shortcuts import render_to_response as render
from django.core.serializers import serialize

import models
import forms

import logging

log = logging.getLogger('works.views')
import apps.notes as notes

from django.utils import text

from tagging.models import TaggedItem, Tag
from conf import settings


from django.core.paginator import Paginator,InvalidPage,EmptyPage

from haystack.query import SearchQuerySet
from haystack.views import SearchView

from utils import UploadHandler, PackageMaker, find_upload, get_citation, SidebarBuilder
from django.contrib.flatpages.views import flatpage


import ingest as ingesttools

# for serving source files
import os, sys
from django.core.servers.basehttp import FileWrapper

# load ingest-related views
from ingest_views import *


def index(request, template="works/index.html"):
    """Default view.  Puts `featured_works` and `entries` into context."""
    ctx = RequestContext(request,{'template' : template})
    features = models.FeaturedWork.objects.order_by('-date_added')
    if len(features) >0:
        feature = features[0]
    else:
        fw = models.Work(title="Featured Work",pk=-1)
        fw.get_absolute_url = lambda : "/voice/works"
        fw.get_cover_image = lambda : "/voice/static/images/image-missing.jpg"
        feature = models.FeaturedWork(work=fw,blurb="No works are currently featured")
    ctx['featured_work'] = feature
    ctx['recent'] = models.Work.objects.filter(available=True).exclude(pk=feature.work.pk).order_by('-created')[:5]
    ctx['entries'] = models.BlogEntry.objects.all()[:5]
    ctx['pageclass'] = 'home'
    return render(template,ctx)

def by_doi(request,doi):
    """Handles requests for works or sections that have DOI (Digital Object Identifier)s;
    redirects to 'canonical' URL.
    """	
    try:
        work=models.Work.objects.get(doi=doi)
        return redirect(work)
    except models.Work.DoesNotExist:
        try:
            section = models.Section.objects.get(doi=doi)
            return redirect(section)
        except models.Section.DoesNotExist:
            return Http404("No object found with that DOI")

def by_slug(request,slug="somevalue",template="works/work-main.html"):
    if slug.isdigit():
        work = get_object_or_404(models.Work,isbn=slug)
        if work.available:
            return redirect(work)
    else:
        work = get_object_or_404(models.Work, slug=slug)
    if work.available:
        view_type = request.GET.get('view', 'html')
        if  view_type == 'source' and request.user.is_superuser:
            sourcefile = os.path.join( work.get_content_directory(), "tei.xml")
            wrapper = FileWrapper(file(sourcefile))
            response = HttpResponse(wrapper, content_type="text/xml")
            response['Content-Length'] = os.path.getsize(sourcefile)
            return response
        elif view_type == 'epub' and request.user.is_staff:
            try:
                epub = utils.get_epub_path(work)
                wrapper = FileWrapper(file(epub))
                response = HttpResponse(wrapper,content_type="application/epub+zip")
                response['Content-Length'] = os.path.getsize(epub)
                response['Content-disposition'] = " attachment; filename=%s.epub" % work.slug
                return response
            except Exception, e:
                log.error("Unable to create epub for %r: %r" % (work, e))
                raise
  
                                    
            
        links = work.links.all()
        return render(template,RequestContext(request,{'work' : work, 'links' : links }))
    else:
        return HttpResponseForbidden("This work is not currently available")
    
    
def unapi(request):
    id = request.GET.get("id", '')
    if not id:
        return HttpResponse("""<formats><format name="MODS" type="application/xml"/></formats>""", content_type="application/xml")
    work = get_object_or_404(models.Work, slug=id)
    fmt = request.GET.get("format", "")
    if not fmt:
        return HttpResponse("""<formats id="%s"><format name="MODS" type="application/xml"/></formats>""" % id, content_type="application/xml")
    if work.available:
        modstxt = utils.get_mods(work)
        return HttpResponse(modstxt, content_type="application/xml")
    return HttpResponse("Nope.")

def workinfo(request,id=0):
    log.info("workinfo called with id %r" % id)
    work = get_object_or_404(models.Work,pk=id)
    
    log.info("Loaded work %r for id %r" % ( work, id))
    return HttpResponse(serialize('json', [work, work.genre], fields = ('title','label', 'isbn', 'author_display', 'available',)), content_type="application/json")
        

def section(request,slug="somevalue",order=1,template="works/work-section.html"):
    log.debug('works.views.section')
    work = get_object_or_404(models.Work,slug=slug)
    if work.available:
        section = get_object_or_404(models.Section,work=work,order=order)
        if request.GET.get('view', 'html') == 'source' and request.user.is_superuser:
            src = utils.get_section_source(section)
            response = HttpResponse(src, "application/xml")
            response['Content-Length'] = len(src)
            return response
            
        if not section.access_controlled or request.user.has_perm("works.can_view_restricted"):
            log.debug('section not access controlled or user has permissions')
            form = notes.forms.AnnotationForm(section, initial={'work_id': work.id})
            ctx = RequestContext(request, {'work': work, 'section' : section, 'form' : form })
            order = int(order)
            if order > 1:
                ctx['prev'] = work.section_set.get(order=order-1)
            if order < work.section_set.count():
                ctx['next'] = work.section_set.get(order=order+1)
            return render(template,ctx)
        else:
            if request.user.is_authenticated():
                return HttpResponseForbidden("Sorry, you do not have permission to view this section")
            else:
                return redirect(reverse("auth_login") + "?next=%s" % section.get_absolute_url())

    else:
        return Http404("This document is not currently available for viewing")

def citation(request,slug=None):
    """
    This method retrieves a formatted citation for a given work
    """
    work = get_object_or_404(models.Work, slug=slug)
    try:
        citation = get_citation(work)
        return HttpResponse(citation)
    except Exception, e:
        return HttpResponse(e)

def _getpage(request):
    try:
        return int(request.GET.get('page', 1))
    except ValueError:
        return 1
    return 1


def browse(request,template="works/browse.html"):
    subject = request.GET.get('subject','')
    keyword = request.GET.get('keyword', '')
    genre = request.GET.get('genre','')
    collection = request.GET.get('collection','')
    ctx = {}

    filters = dict(available=True)
    if subject:
        filters.update(dict(subjects__label=subject))
        ctx['subject'] = subject
    if genre:
        filters.update(dict(genre__label=genre))
        ctx['genre'] = genre
    if collection:
        filters.update(dict(collection__name=collection))
        ctx['collection'] = collection
    results = models.Work.objects.filter(**filters).order_by('title','subtitle')            
    if keyword:
        tag = Tag.objects.get(name=keyword)
        ctx['keyword'] = keyword
        results = TaggedItem.objects.get_by_model(results, tag)


    pagenum = _getpage(request)
    paginator = Paginator(results, settings.WORKS_BROWSE_PAGESIZE)
    try:
        page = paginator.page(pagenum)
    except (InvalidPage,EmptyPage):
        page = paginator.page(paginator.num_pages)
    ctx.update( {'page' : page, 'title' : 'Browse' } )

    return render(template,RequestContext(request, ctx))

def advanced_search(request,template="search/advanced-search.html"):
    ctx = {}
    action = request.GET.get("action", False)
    if action:
        form = forms.AdvancedSearchForm(request.GET)
        if form.is_valid():
            ctx['query'] = form.build_query_string()
            qs = SearchQuerySet()
            print form.params
            results = qs.filter( **form.params )
            paginator = Paginator(results,settings.WORKS_BROWSE_PAGESIZE)
            pagenum = _getpage(request)
            try:
                page = paginator.page(pagenum)
            except (InvalidPage,EmptyPage):
                page = paginator.page(paginator.num_pages)
            ctx['page'] = page
    else:
        ctx['query'] = "Not that you entered one ..."
        form = forms.AdvancedSearchForm()
        
    ctx['form'] = form        
    return render(template, RequestContext(request, ctx))


class WorkSearchView(SearchView):
    def __name__(self):
        return "WorkSearchView"

    def _convert_results(self, object_list):
        works = []
        try:
            for res in filter(lambda y: y is not None, object_list):
                ct = res.content_type()
                if ct == 'works.section':
                    work = res.object.work
                elif ct == 'works.work':
                    work = res.object
                if not work in works:
                    works.append(work)

            sections = [ x.object for x in object_list if x is not None and x.content_type() == 'works.section' ]

            rv= []

            for work in works:
                work.work = work
                rv.append(work)
                for section in sections:
                    if section.work == work:
                        rv.append(section)
            return rv
        except AttributeError, e:
            # 'NoneType' object has no attribute 'makefile' indicates that the
            # Solr service is not currently accepting requests.
            # this is a limitation in pysolr
            if "'makefile'" in str(e):
                raise AttributeError("Search server is currently not available")
            print str(e)
            raise e


    def build_page(self):
        # (paginator, string representation)
        paginator,page = super(WorkSearchView,self).build_page()
        page.object_list = self._convert_results(page.object_list)
        return paginator,page

    #def get_results(self):
    #    results = super(WorkSearchView,self).get_results()
    
# invoke this if you want to see the error page -- for testing!
def error_out(request):
    foo = None
    print foo.some_attribute
    

def server_error(request):
    exc_info = sys.exc_info()
    log.exception("%s" % request.path)
    return render("500.html", { 'server_error' : True })

def profile(request,profile_id = None,template="works/user-profile.html"):
    log.debug('works.views.profile')
    if profile_id is None or len(profile_id) == 0:
        if request.user.is_anonymous():
            return redirect('works:index')
        prof = request.user.get_profile()
        log.info("Redirecting to profile for %r and next='%s'" % (prof, request.GET.get('next', '[null]')))
        url = 'next' in request.GET and prof.get_absolute_url() + "?next=%s" % request.GET['next'] or prof.get_absolute_url()
        log.debug('works.views.profile - redirect url: '+url)
        return redirect(url)

    prof = get_object_or_404(models.UserAccount,pk=int(profile_id))
    log.debug('works.views.profile - prof: '+str(prof))

    own_profile = ( request.user.get_profile().pk == int(profile_id) )
    if own_profile and request.method == 'POST':
        log.debug('works.views.profile - POST request: '+str(request));
        user_form = forms.UserForm(data=request.POST, instance=prof.user, prefix="user")
        account_form = forms.UserAccountForm(data=request.POST,instance=prof,prefix="account")
        log.debug(prof.get_absolute_url())
        if user_form.is_valid() and account_form.is_valid():
            user_form.save()
            account_form.save()
            if 'next' in request.POST:
                return HttpResponseRedirect(request.POST['next'])
            
            return HttpResponseRedirect(prof.get_absolute_url())
    else:
        user_form = forms.UserForm(instance=prof.user, prefix="user");
        account_form = forms.UserAccountForm(instance=prof,prefix="account")

    # inactive profiles should not be visible; they don't exist yet really
    if not prof.user.is_active:
        return Http404("This user does not exist")

    ctx = RequestContext(request,{'profile':prof })
    show_profile = prof.is_public or own_profile or request.user.is_staff
    ctx['show_profile'] = show_profile
    if own_profile:
        # editing_forms = [ forms.UserForm(instance=request.user,prefix="user"), forms.UserAccountForm(instance=prof,prefix="account") ]
        editing_forms = [user_form, account_form]
        ctx['forms'] = editing_forms
        if 'next' in request.GET:
            ctx['next'] = request.GET['next']

    return render(template,ctx)

def search_in_work(request, work_id):
    import pysolr
    solr = pysolr.Solr(settings.HAYSTACK_SOLR_URL)
    query = request.GET.get('query', 'myxlplix') + " AND parentId:works.work.%s" % work_id
    
    res = solr.search(query)
    rv = []
    for r in res:
            rv.append(r)
    import simplejson as json
    
    return HttpResponse(json.dumps(rv), content_type="application/json")


def collection_index(request):
    try:
        collections = models.Collection.objects.all()
    except DoesNotExist:
        collections = []
    return render("collections/index.html", RequestContext(request, {'collections': collections, 'collections_count':len(collections)}))
    
def collection_by_id(request, id="id", template="collections/collection.html"):
    collection = get_object_or_404(models.Collection, id=id)
    return render(template,RequestContext(request,{'collection' : collection }))
    
def collection_by_slug(request, slug="collection_slug", template="collections/collection.html"):
    log.debug('views.collection_by_slug')
    log.debug('slug: '+slug)
    collection = get_object_or_404(models.Collection, slug=slug)
    return render(template, RequestContext(request, {'collection' : collection }))

def collection_browse(request, slug="slug", browse_by="browse_by", template="collections/collection_browse.html"):
    log.debug('views.collection_browse')
    log.debug('slug: '+slug)
    log.debug('browse_by: '+browse_by)
    collection = get_object_or_404(models.Collection, slug=slug)
    return render(template, RequestContext(request, {'collection':collection}))

def collection_introduction(request, slug="slug"):
    collection = get_object_or_404(models.Collection, slug=slug)
    return flatpage(request, collection.url_base+'/introduction/')
    
def collection_about(request, slug="slug"):
    collection = get_object_or_404(models.Collection, slug=slug)
    return flatpage(request, collection.url_base+'/about/')
    
def collection_about_staff(request, slug="slug"):
    collection = get_object_or_404(models.Collection, slug=slug)
    return flatpage(request, collection.url_base+'/about/staff/')
