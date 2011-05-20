import cdla.xmlmodels as xmlmodels
from lxml import etree
import os


class TEIDocument(xmlmodels.XMLProcessor):
    
    def __init__(self,doc):
        super(TEIDocument,self).__init__(doc)
        self.doc = doc

    def get_abstract_html(self):
        ab_el = self.get_evaluator()("//tei:teiHeader//tei:note[@type='abstract']")
        if not ab_el:
            return u"<p>No abstract for this document</p>"
        xsltdoc = etree.parse(os.path.join( os.path.dirname(__file__),"abstract2html.xsl"))
        xsl = etree.XSLT(xsltdoc)
        html_result = xsl(ab_el[0])
        return etree.tostring(html_result,pretty_print=True).strip()
        
    def get_keywords(self):
        """
        Extracts keywords from TEI document; I could not find a good way to put these into MODS.
        //tei:keywords[@scheme="urn:keywords"]/tei:list/tei:item
        The scheme "UNCP" is also accepted for backwards combatibility
        """
        ev = self.get_evaluator()
        keywords = [x.text.strip() for x in ev("//tei:teiHeader//tei:keywords[@scheme='urn:keywords' or @scheme='UNCP']/tei:list/tei:item") ]
        return keywords
    
    def target_to_href(self,target):
        """Converts ref/@target attributes for 'identifier' type links to point to privileged locations;
        e.g. "oclc:NNNNNNN" should point to "http://worldcat.org/oclc/NNNNNN"
        """
        prefix, identifier = target.split(":",1)
        if prefix == 'doi':
            return "http://dx.doi.org/%s" % identifier
        else:
            return "http://worldcat.org/%s/%s" % ( prefix, identifier )

    def get_links(self):
        """Finds the labeled links in the TEI Header.
            XPath: `tei:note[@type=links]`
            returns a list of dicts with 'href' and 'label' keys
        """
        ev = self.get_evaluator()
        refelements = ev("//tei:teiHeader//tei:note[@type='links']/tei:ref")
        rv = []
        for ref in refelements:
            if ref.attrib.get('type') == 'uriref':
                rv.append({'href':ref.attrib.get('target'), 'label':ref.text})
            elif ref.attrib.get('type') == 'identifier':
                rv.append({ 'href' : self.target_to_href(ref.attrib.get('target')), 'label' : ref.text })
        return rv
    
    def page_count(self,section=None):
        if section is not None:
            ev = self.get_evaluator(section)
        else:
            ev = self.get_evaluator()
        return int( ev("count(//tei:pb)") )
