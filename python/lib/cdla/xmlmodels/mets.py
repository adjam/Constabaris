#!/usr/bin/env python

# $Id$

# coding=utf-8

from lxml import etree
import re
from cdla.util import roman
import os
from cdla.xmlmodels import XMLProcessor, get_prefix_uri, ns

import logging

log = logging.getLogger("xmlmodels.mets")


# post 2.5, strptime is also in datetime
import time, datetime

re_iso = re.compile(r"^\d{4}-\d{2}-\d{2}")

def postelize_date(datestr):
    fmts = ( "%Y", "%B %d, %Y", "%Y-%m",)
    for fmt in fmts:
        try:
            y,m,d = time.strptime(datestr,fmt)[:3]
            return datetime.date(y,m,d).strftime("%Y")
        except ValueError, vx:
            pass
    raise ValueError("'%s' could not be parsed by any supported formats" % datestr)

class Author(object):
    """Encapsulation of author info as it might be found in the TEI document
    """
    def __init__(self,display_form,reg_form=None,user_id=None,editor=False):
        self.display_form = display_form
        self.reg_computed = False
        if reg_form is not None:
            self.reg_form = reg_form
        else:
            self.reg_form = Author._compute_regform(display_form)
            self.reg_computed = True
        self.editor = editor
        self.user_id = user_id

    def _compute_regform(display_form):
        p = display_form.split()
        return "%s, %s" %( p[-1], " ".join(p[:-1]) )
    
    _compute_regform = staticmethod(_compute_regform)

    def __repr__(self):
        rv = self.display_form
        if self.editor:
            rv += " [e]"
        return rv

    def __unicode__(self):
        rel = self.editor and " [e]" or ""
        return u"%s%s (%s)" % ( self.display_form, rel, self.reg_form )
        
class AttrDict(dict):
    """Dictionary subclass that lets you access elements using standard
    attribute access syntax, e.g. attrdict['foo'] => attrdict.foo are equivalent; care must be taken to make sure that the keys are valid python names
    """
    def __init__(self,init={}):
        dict.__init__(self,init)

    def __getstate__(self):
        return self.__dict__.items()

    def __setstate__(self,items):
        return self.update(items)

    def __repr__(self):
        return "%s(%s)" % (self.__class__.__name__,dict.__repr__(self))

    def __setitem__(self,key,value):
        return super(AttrDict,self).__setitem__(key,value)

    def __getitem__(self,key):
        return super(AttrDict,self).__getitem__(key)
    def __delitem__(self,key):
        return super(AttrDict,self).__delitem__(key)
    __getattr__ = __getitem__
    __setattr__ = __setitem__

    def copy(self):
        cp = super(AttrDict,self).copy()
        return AttrDict(cp)

class File(object):
    """A mets:file element in a METS Document"""
    def __init__(self,path,mime_type):
        self.path = path
        self.filename = os.path.basename(self.path)
        self.mime_type = mime_type

    def is_image(self):
        return self.mime_type.startswith("image/")
    
    def is_html(self):
        return self.mime_type == "application/xhtml+xml"

    def is_tei(self):
        return self.mime_type == 'application/tei+xml'
    
    def __cmp__(self,other):
        if isinstance(File,other):
            return cmp(self.path, other.path)
        return cmp(unicode(self), unicode(other))

    def __repr__(self):
        return "%s => %s" % ( self.path, self.mime_type )

class METSDocument(XMLProcessor):
    """
    Represents information that can be extracted from a METS document
    generated for use in LCRM.
    """
    
    def __init__(self,doc):
        self.doc = doc
        self.files = self._get_files()
        self.images = [ img for img in self.files.values() if img.is_image() ]
        self.roman_re = re.compile(r"^[ivxlcdm]+$",re.IGNORECASE)
        self._process_header()

    def is_roman(self,text):
        return self.roman_re.match(text)

    def _get_segments(self):
        """Retrieves the info about segments; these are represented in METS as
        mets:div elements"""
        if hasattr(self,'_segs'):
            return self._segs
        xev = self.get_evaluator()
        self._segs = []
        
        for idx, divel in enumerate(xev("//mets:div")):
            divev = self.get_evaluator(divel)
            div = AttrDict({'title' : self.normalize_space(divel.get("LABEL")), 'order': idx +1})
            file_id = divev("mets:fptr/@FILEID")[0] # mets:fptr
            div.file = self.files[file_id]
            div.source_id = file_id
            pages = divev("mets:fptr/mets:area[starts-with(@ID, 'page-')]")
            div.page_count = len(pages)
            if div.page_count > 0:
                ps = pages[0].get("ID")[5:]
                if self.is_roman(ps):
                    div.page_number_style = "roman"
                    div.page_start = roman.to_decimal(ps)
                    div.page_end = roman.to_decimal(pages[-1].get("ID")[5:])
                else:
                    div.page_number_style = "arabic"
                    div.page_start = int(ps)
                    div.page_end = int(pages[-1].get("ID")[5:])
            else:
                div.page_start = -1
                div.page_end = -1
            self._segs.append(div)
        self._segs.sort( lambda x,y : cmp(x.order,y.order) )
        return self._segs
    segments = property(_get_segments)
    
    def _get_media(self):
        if hasattr(self,'_media'):
            return self._media        
        hrefatt = self.clark_name("xl","href")
        xev = self.get_evaluator()
        self._media = []
        for fel in xev("//mets:fileGrp[@ID='media']/mets:file/mets:FLocat"):
            href=fel.get(hrefatt)
            mimetype = fel.getparent().get("MIMETYPE")
            self._media.append( { 'href' : href, 'mimetype' : mimetype } )
        return self.media
    media = property(_get_media)

    def _get_files(self):
        hrefatt = self.clark_name('xl', 'href')
        xev = self.get_evaluator()
        file_elements = xev("//mets:fileSec[@ID='content-files']/mets:fileGrp/mets:file")
        files = {}
        for el in file_elements:
            mime_type = el.get("MIMETYPE")
            file_id = el.get("ID")
            path = el[0].get(hrefatt)
            files[file_id] = File(path,mime_type)
        return files

    def _xpath(self, ev, path):
        result = ev(path)
        if len(result) > 0:
            return result[0].text

    def _process_origin_info(self,ev):
        oev = self.get_evaluator(ev("mods:originInfo")[0])
        pdate = self._xpath_text(oev,"mods:dateIssued")
        m = re_iso.match(pdate)
        if not m:
            pdate = postelize_date(pdate)
        else:
            pdate = pdate[:4]
        d = {"publishedYear" : pdate }
        d["publisherName"] = self._xpath_text(oev,"mods:publisher")
        d['publisherPlace'] = self._xpath_text(oev,"mods:place/mods:placeTerm[@type='text']")
        return d

    def _find_authors(self,ev):
        authors = []
        authfinder = "//mods:mods/mods:name[mods:role[mods:roleTerm[@type='code']]]"
        for mods_name in ev(authfinder):
            nev = self.get_evaluator(mods_name)
            df = self._xpath_text(nev, ".//mods:displayForm")
            reg_element = nev(".//mods:namePart")
            type_code = nev(".//mods:role/mods:roleTerm[@type='code'][1]")[0].text
            editor = type_code == 'edt'
            if reg_element:
                reg_formtext = reg_element[0].text
                authors.append(Author(df, reg_form=reg_formtext,editor=editor))
            else:
                authors.append(Author(df))
        return authors

    def _process_header(self):
        md = AttrDict()
        ev = self.get_evaluator()
        mods = ev("//mods:mods")[0]
        mev = self.get_evaluator(mods)
        md.title = self._xpath_text(mev,"mods:titleInfo/mods:title")
        md.subtitle = self._xpath_text(mev, "mods:titleInfo/mods:subTitle")
        md.isbn = self._xpath_text(mev, "//mods:identifier[@type='isbn']")
        md.doi = self._xpath_text(mev, "//mods:identifier[@type='doi']")
        try:
            md.genre_name = self._xpath_text(mev, ".//mods:genre")
            log.debug("Read genre '%s' from MODS header" % md.genre_name)
        except Exception,e :
            log.debug("Found no genre in MODS, using default of 'Book'")
            md.genre_name = 'Book'
        md.update( self._process_origin_info(mev) )
        md.authors = self._find_authors(mev)


        md.description = self.normalize_space(self._xpath_text(mev, "mods:abstract"))



        subject_elements = mev("mods:subject[@authority='lcsh']/mods:topic")
        if len(subject_elements) > 0:
            md.subjects = [ self.normalize_space(x.text) for x in subject_elements ]
        else:
            md.subjects = []
            
        md.subjects.sort()
        self.metadata = md

def _main(filename):
    doc = etree.parse(filename)
    mets = METSDocument(doc)
    for k, v in mets.metadata.items():
        print "%s : %s" % ( k, v )
    for seg in mets.segments:
        print "%s => %s (%s-%s, %d pp)" % ( seg.title , seg.file.path, seg.page_start, seg.page_end, seg.page_count )
    for m in mets.media:
        print "%s => %s" % ( m['href'], m['mimetype'] )
    return mets
        
if __name__ == '__main__':
    doc = _main("/home/adamc/mets.xml")
        
            
