__doc__ = """Views related to ingest and update of works by administrators.
Usage: in main views.py, use `from ingest_views import *`
"""

import zipfile
import utils
import ingest as ingesttools
import forms

from django.http import HttpResponse,Http404, HttpResponseForbidden,HttpResponseRedirect
from django.views.decorators.http import require_POST
from django.contrib.auth.decorators import user_passes_test
from django.template import RequestContext
from django.shortcuts import render_to_response as render
from django.core.urlresolvers import reverse

import logging
log = logging.getLogger("works.ingest.view")


def _get_admin_url(work):
    return reverse("admin:%s_%s_change" % ( work._meta.app_label, work._meta.module_name ) , args=(work.id,))

def ingest(request,template="works/upload.html",
           template_success="works/ingest-verify.html"):
    """Called to show form for ingest and to accept upload of ingest packages."""
    if request.method == 'POST':
        form = forms.UploadForm(request.POST,request.FILES)
        if form.is_valid():
            try:
                package, file_key = _handle_upload(request.FILES['file'])
                context = ingesttools.IngestContext(package, license=form.cleaned_data['license'])
                action = ingesttools.IngestAction(context)
                ctx = RequestContext(request, action.execute())
                ctx['upload_key'] = file_key
                request.session['current_work'] = action.work
                return render(template_success,ctx)
            except zipfile.BadZipfile, bzf:
                form = forms.UploadForm(request.POST)
                form.errors['file']= ["Not a valid ZIP file"]
    else:
        form = forms.UploadForm()
    return render(template, RequestContext(request,{'form': form }))

ingest = user_passes_test(lambda u: u.is_superuser)(ingest)

@require_POST
def commit(request,template="works/ingest-commit.html"):
    """Commits a currently in-process ingest package, including the Work,
    any Sections, new Publishers, and new Subjects.

    Requires active session.
    """
    file_key = request.POST['upload_key']
    package_file = utils.find_upload(file_key)
    if package_file is None:
        return HttpResponse("Can't find your upload package.  You may have waited too long in between submitting it and committing it.")
    context = ingesttools.IngestContext(package_file)
    work = request.session['current_work']
    action = ingesttools.IngestAction(context)
    ctx = action.execute(work=work,commit=True)
    del request.session['current_work']
    ctx['admin_url'] = _get_admin_url(work)
    return render(template, RequestContext(request, ctx ))

commit = user_passes_test(lambda u: u.is_superuser)(commit)

def update(request,id=None,template="works/ingest/update.html", success_template="works/ingest/update-success.html"):
    """Handles re-ingest of bundled HTML"""
    
    if request.method == 'GET':
        form = forms.UpdateWorkForm()
        return render(template, RequestContext(request,{ 'form' : form }))
    
    form = forms.UpdateWorkForm(request.POST, request.FILES)
    
    
        
    if not form.is_valid():
        return render(template, RequestContext(request,{'form' : form}))

    log.info("handling upload")
    work = form.cleaned_data['work']
    if 'cover' in request.FILES:
        log.info("handling cover art replacement")
        cfile = request.FILES['cover']
        ofile = "%s/cover.jpg" % work.get_content_directory()
        f = open(ofile, "wb")
        for chunk in cfile.chunks():
            f.write(chunk)
        f.close()        
        message = "Uploaded %s (%d bytes) to %s" % ( cfile.name, cfile.size, ofile )
        context = RequestContext(request, {'message' : message, 'admin_url' : _get_admin_url(work)})
        context['work'] = work
        context['cover_art'] = True
        return render(success_template, context)
    
    if 'package' in request.FILES:
        import traceback
        log.debug("handling HTML update for %s" % unicode(work))
        try:
            pf = request.FILES['package']
            package, key = _handle_upload(pf)
            ctx = ingesttools.IngestContext(package)
            action = ingesttools.IngestAction(ctx)
            result = action.overwrite_content(work)
            context = RequestContext(request, result)
            context['admin_url'] = _get_admin_url(work)
            return render(success_template, context)
        except Exception, e:
            res = traceback.format_exc()
            log.exception("Encountered exception trying update", e)
            return HttpResponse("Encountered an error: %r" % e)
    
    form.errors.append("You need to upload either the cover art or a (pre-)ingest package.")
    return render(template,RequestContext(request,{'form': form }))

update = user_passes_test(lambda u: u.is_superuser)(update)

def cleanup(request):
    log.info("Cleaning up unused works directories")
    from management.commands.static_cleanup import Command
    cleaner = Command()
    cleaner.handle()
    baleted = cleaner.deletables
    return HttpResponse("Cleaned up %d unused directories: %r" %(len(baleted), baleted))

cleanup = user_passes_test(lambda u: u.is_superuser)(cleanup)

# not a view method!
def _handle_upload(uploadedFile):
    handler = utils.UploadHandler(uploadedFile)
    return handler.process()