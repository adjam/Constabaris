from django.template import Library,Node,Variable,TemplateSyntaxError,Context
from django.template.loader import get_template
try:
    from urlparse import parse_qs
except ImportError:
    from cgi import parse_qs
from urlparse import urlparse, urlunsplit
from urllib import urlencode
__doc__ = """Template tags for rendering search results"""

register = Library()

_templates = {
    "work" : "search/result/work.html",
    "section" : "search/result/section.html",
    "note" : "search/result/note.html"
}

class SearchResultNode(Node):
    """
    Node that displays search results.
    """

    def __init__(self,result_var):
        self.result = Variable(result_var)

    def render(self,context):
        result = self.result.resolve(context)
        ct = result.__class__.__name__.lower()
        if ct in _templates:
            tmpl = get_template(_templates[ct])
            if ct == 'section':
                user = context.get('request').user
                can_view = not result.access_controlled or user.has_perm('can_view_restricted')
                context['can_view'] = can_view
            return tmpl.render(context)


def search_result(parser,token):
    try:
        tag_name, result = token.split_contents()
    except ValueError:
        raise TemplateSyntaxError("%s requires a single argument" % token.contents.split()[0])
    return SearchResultNode(result)

search_result = register.tag(search_result)

@register.filter(name="base_search_url")
def base_search_url(value):
    """Gets back a search URL with the 'page' parameters removed, so it can be added back in a principled manner
    The expected value is that returned by request.get_full_path"""
    parts = urlparse(value)
    params = parse_qs(parts[4])
    #for p in params:
    #    if isinstance(params[p], list):
    #        params[p] = params[p][0]

    if 'page' in params:
        del params['page']
    # parts[3] is 'params, i.e. stuff following a semicolon; need to get rid of that for the unsplit operation
    parts = list(parts)
    del parts[3]
    parts[3] = urlencode(params,True) # handle multivalues
    return urlunsplit(parts)