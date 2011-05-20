#!/usr/bin/env python

from lxml import etree
from copy import deepcopy
import httplib2
from urllib import urlencode

import logging
__doc__ = """Utility for accessing UNC Library's Citation Builder"""

#: Citation Styles supported by the builder.
STYLES  = { 'mlastyle': { 
    "display_name" : "MLA Style",
    "description" : "Modern Language Association Style", 
    "class" : "mlaindent"
    },
    'apastyle': {
        "display_name" : "APA Style",
        "description" : "American Psychological Association Style",
        "class" : "apaindent"
    },
    'csestyle': {
        "display_name" : "CBE/CSE Style",
        "description" : "Council of Science Editors Style",
        "class" : "cbeindent"
        },
    'chicago-bib' : {
            "display_name" : "Chicago (Bibliographic)",
            "description" : "Chicago Manual Of Style Bibliographic Form (Humanities)",
            "class" : "chicindent",
            "order" : 0
    },
    'chicago-reflist' : {
            "display_name" : "Chicago (Reference List)",
            "description" : "Chicago Manual of Style Reference List Form (Sciences)",
            "class" : "chicindent",
            "order" : 1
    }
} 

#: Types of works that may be cited, including the URL to the page for that citation type.
TYPES = {
    'book' : { 'url' : "http://www.lib.unc.edu/house/citationbuilder/bookcitation.html" },
    'journal' : { 'url' : 'http://www.lib.unc.edu/house/citationbuilder/journalcitation.html'}
    }

def recode_dict(d):
    rv = {}
    for k,v in d.items():
        key = k.encode('utf-8')
        if isinstance(v,unicode):
            val = v.encode('utf-8')
        else:
            val = v
        rv[key] = val
    return rv

def get_citation(info,cite_type='book',styles=STYLES.keys(),format="html"):
    """Gets citations for a book, returns a list

    info -- dict containing the information in the citation

    Keyword Arguments:
    cite_type -- the type (from TYPES.keys()) of work to be cited
    styles -- the name or names (from STYLES.keys()) of the styles to be cited
    format -- the format in which to return the citations (e.g. 'text', 'html'); note that formatting may be lost
              when using 'text'; if the format is unrecognized, text will be returned.

    """
    log = logging.getLogger("works.utils.citebuilder")
    log.debug(unicode(info))
    if isinstance(styles, type("")) or isinstance(styles,type(u"")):
        styles = ( styles,)
    try:
        url = TYPES[cite_type]['url']
    except KeyError:
        raise KeyError("Unknown record type '%s'" % cite_type )
    cl = httplib2.Http()
    data = recode_dict(info.copy())
    data.update({"status": "submitted"})
    requrl = "%s?%s" % ( url, urlencode(data) )
    resp,content = cl.request(requrl,"GET")
    doc = etree.HTML(content)
    rv = []
    for sname in styles:
        if not sname in STYLES:
            raise KeyError("Unknown citation style '%s'; known types are %r" % ( sname, STYLES.keys() ))
        style = STYLES[sname]
        cls = style['class']
        order = style.get("order", 0)
        cites = doc.xpath(".//p[@class='%s']" % ( cls ))
        if cites:
            cite = deepcopy(cites[order])
            if format == "html":
                cite.tail= u""
                cite.attrib['class'] = 'citation %s' % sname
                rv.append( etree.tostring(cite) )
            else:
                rv.append( "".join(cite.xpath(".//text()")))
    return rv

if __name__ == '__main__':
    info = { 'authorlname1' : 'WriterPerson',
             'authorfname1' : 'Dakota',
             'authormname1' : 'J.',
             'title' : "Writing For Authors: Doing What You Do",
             'year' : '2009',
             'pages' : '153',
             'publisher' : 'Pleonasm Press',
             'location' : 'Anytown, USA'
            }
    for cite in get_citation(info, styles="chicago-bib"):
        print cite


    
