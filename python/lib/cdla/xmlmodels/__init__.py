# $Id$

from lxml import etree
import re
from cdla.util import roman
import os

__doc__ = """
Provides classes that simplify working with various information-rich
XML documents.  See subpackages for details"""

ns = { 'mets' : 'http://www.loc.gov/METS/',
       'tei' : 'http://www.tei-c.org/ns/1.0',
       'mods' : 'http://www.loc.gov/mods/v3',
       'xl' : 'http://www.w3.org/1999/xlink',
       'x' : 'http://www.w3.org/1999/xhtml' }

def get_prefix_uri(prefix):
    """Gets the typical URI that is normally mapped to the specified prefix.
    """
    return ns.get(prefix, None)

class XMLProcessor(object):
    """Base class for objects that process XML; provides utilities
    for accessing parts of the document, performing XPath queries,
    etc.
    """

    def __init__(self,doc):
        self.doc = doc

    def get_evaluator(self,base=None):
        if base is None:
            base = self.doc
        return etree.XPathEvaluator(base,namespaces=ns)

    def clark_name(self,nsprefix,name):
        """Gets the "Clark name" of an element or attribute, that is
        "{[namespace uri]}[element or attribute name]"
        """
        return "{%s}%s" % ( ns[nsprefix], name )

    def _xpath_text(self, ev, path,default=None):
        result = ev(path)
        if len(result) > 0:
            return result[0].text
        return default

    def normalize_space(self,text):
        if text is None: return None
        return " ".join(text.split())
