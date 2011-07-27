from django.template import Library,Node,Variable,TemplateSyntaxError
from django.template.defaulttags import ssi,SsiNode
from django.template.loader import render_to_string
from apps.works.utils import SidebarBuilder

from django.core.cache import cache

register = Library()

import logging

log = logging.getLogger("works.tags")

def truncate(txt,length=50):
    return len(txt) <= length and unicode(txt) or unicode(txt[:48]) + u"\u2026"

class DynamicSsiNode(SsiNode):
    log.debug('dynamicssi node')
    """
    Subclass of SsiNode in defaulttags to allow use of dynamic
    values for the path of the included file.
    """
    def render(self,context):
        if self.filepath in context:
            self.filepath = context[self.filepath]
            log.debug('FILEPATH: '+self.filepath)
        return super(DynamicSsiNode,self).render(context)


def dynamicssi(parser,token):
    """
    Basically, we just reassign the class so that the returned Node
    object will call the right render method.
    """
    node = ssi(parser,token)
    node.__class__ = DynamicSsiNode
    return node

dynamicssi = register.tag(dynamicssi)

def _user_can_view(user,section):

    if not section.access_controlled:
        return True
    return user.has_perm('works.can_view_restricted')


class NavigationNode(Node):
    def __init__(self,current_section):
        self.current_section = Variable(section)

    def render(self,context):
        current_section = self.current_section.resolve(context)

class SectionListNode(Node):
    def __init__(self,work,current_section=None):
        self.work = Variable(work)
        if current_section is not None:
            self.current_section = Variable(current_section)
        else:
            self.current_section = None
            
    def render(self,context):
        work = self.work.resolve(context)
        if self.current_section is not None:
            current_order = self.current_section.resolve(context).order
        else:
            current_order = -1
        user = context.get('request').user
        sections = work.get_sections_ordered()
        if len(sections) == 1:
            if _user_can_view(user,sections[0]):
                return """<li class="first last"><a href="%s" title="%s">Full Text</a>""" % (sections[0].get_absolute_url(), sections[0].title) 
            else:
                return """<li class="first last">Full Text</li>"""
        lines = []
        for ct, sect in enumerate(sections):
            li_classes = ['section']
            a_classes = []
            if sect.comment_count > 0:
                a_classes.append("has-comments")
            if sect.order == current_order:
                li_classes.append("current")
            if ct == 0:
                li_classes.append("first")
            if ct == len(sections)-1:
                li_classes.append("last")
            li_class_value = " ".join(li_classes)
            a_class_value = " ".join(a_classes)
            if li_class_value:
                li_class_string = " class='%s'" % li_class_value
            else:
                li_class_string = ''
            if a_class_value:
                a_class_string = " class='%s'" % a_class_value
            else:
                a_class_string = ''
                
            lines.append("""<li%s><a%s href="%s" title="%s">%s</a> </li>""" % ( li_class_string, a_class_string, sect.get_absolute_url(), sect.title+' has '+str(sect.comment_count)+' comment(s)', truncate(sect.title, 28) ) )
        return "\n".join( lines )

def sectionlist(parser,token):
    try:
        tokens = token.split_contents()
        if len(tokens) == 3:
            tagname, work, current_section = tokens
        else:
            tagname,work, current_section = tokens[0], tokens[1], None
        return SectionListNode(work, current_section)
    except ValueError:
        raise TemplateSyntaxError, "%r requires one or two arguments, work and [optional] section currently being shown" % tagname


sectionlist= register.tag('sectionlist',sectionlist)

class SectionInfoNode(Node):

    def __init__(self, section, current_section=None, counter=0):
        self.section = Variable(section)
        if current_section is not None:
            self.current_section = Variable(current_section)
        else:
            self.current_section = None

    def render(self,context):
        rendered_sect = self.section.resolve(context)
        if self.current_section is not None:
            current_sect = self.current_section.resolve(context)
            current_order = current_sect.order
        else:
            current_order = -1
        req = context.get('request')
        if req is None:
            return "<span class='error'>Called outside of a request context</span>"
        user = req.user

        if _user_can_view(user,rendered_sect) and rendered_sect.order != current_order:
            return """<li>
            <a href='%s' title='%s'>%s</a>
            </li>""" % ( rendered_sect.get_absolute_url(), rendered_sect.title, truncate(rendered_sect.title,28))
        return """<li class="current">
        <span title="%s">%s</span>
       
        </li>""" % ( rendered_sect.title, truncate(rendered_sect.title, 28) )
    
    #  <ul id="si-subsections"><li/>
    #    </ul>

def _user_can_view(user,section):

    if not section.access_controlled:
        return True
    return user.has_perm('works.can_view_restricted')


def sectioninfo(parser,token):
    try:
        tokens = token.split_contents()
        if len(tokens) == 4:
            tagname, section, current_section, counter = tokens
        else:
            tagname,section,current_section, counter = tokens[0], tokens[1], None, 0
        return SectionInfoNode(section,current_section, counter)
    except ValueError:
        raise TemplateSyntaxError, "%r requires two arguments, section to show and section currently being shown" % tagname


sectioninfo = register.tag('sectioninfo',sectioninfo)

def show_entry(entry):
    date = entry.created
    return { 'entry' : entry, 'date' : date }

register.inclusion_tag('tags/entry.html')(show_entry)

@register.inclusion_tag('tags/section_navigation.html',takes_context=True)
def section_navigation(context):
    return context

def genre_browse():
    if cache.get('sidebar-browse') is None:
        sq = SidebarBuilder()
        cache.set('sidebar-browse',sq.get_facets(), 500)
    # print type(cache.get('sidebar-browse'))
    return { 'browseables' : cache.get('sidebar-browse') }

register.inclusion_tag('tags/browse-genre.html')(genre_browse)

def collection_browse():
    # if cache.get('collection-browse') is None:
    #     sq = SidebarBuilder()
    #     cache.set('collection-browse', sq.get_collections(), 500)
    # return {'collections':cache.get('collection-browse')}
    sq = SidebarBuilder()
    collections = sq.get_collections()
    return {'collections': collections, 'collection_count': len(collections)}
register.inclusion_tag('tags/browse-collection.html')(collection_browse)

class PaginateResultsNode(Node):
    def __init__(self,pagetoken, gettoken):
        self.page = Variable(pagetoken)
        self.getvars = Variable(gettoken)
    
    def render(self,context):
        page = self.page.resolve(context)
        getvars = self.getvars.resolve(context)
        get_params  = ''
        for k,v in getvars.iteritems():
            if k != 'page':
                if get_params != '':
                    get_params += '&'
                get_params += k+'='+v
        
        pnum = page.number
        page_skips = False
        if page.has_previous():
            previous_page = page.previous_page_number()
            previous_pages = range(1, pnum)
            if len(previous_pages) > 5:
                previous_pages = [ previous_pages[0] ] + [-1] + previous_pages[-5:]
                page_skips = True
        else:
            previous_pages = []
            previous_page = 0
                
        if page.has_next():
            next_page = page.next_page_number()
            next_pages = range(pnum +1, page.paginator.num_pages + 1)
            if len(next_pages) > 5:
                next_pages = next_pages[:5] + [-1] + [ next_pages[-1] ]
                page_skips = True
        else:
            next_pages = []
            next_page = 0
            
        return render_to_string('tags/pagination_links.html', {'page': page, 'previous_pages':previous_pages, 'next_pages': next_pages, 'page_skips':page_skips, 'previous_page':previous_page, 'next_page': next_page, 'get_params': get_params})
        
    

def paginate_results(parser, token):
    try:
        tagname, pagetoken, gettoken = token.split_contents()
        return PaginateResultsNode(pagetoken, gettoken)
    except ValueError:
        raise TemplateSyntaxError, "%r requires two arguments, a django Page object" % 'paginate_results'
    
register.tag('paginate_results', paginate_results)
    
    
