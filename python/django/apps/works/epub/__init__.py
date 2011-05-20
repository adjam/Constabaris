#!/usr/bin/env python

import zipfile
from lxml import etree
import os
import re

from cStringIO import StringIO

EPUB_MIMETYPE = "application/epub+zip"

CONTENT_EXTENSIONS = ('.html', '.jpg', '.png', '.gif', '.svg',)

class Packager(object):
    def __init__(self,work,use_disk=False):
        self.work = work
        self.use_disk = use_disk
        self.section_map = {}
        if hasattr(work,'section_set'):
            for sect in work.section_set.all():
                self.section_map[ os.path.abspath( sect.get_filename() ) ] = sect

    def _meta(self):
        if not hasattr(self, 'opf'):
            opf_xsl_file = os.path.join( os.path.dirname( __file__ ),"mets2opf.xsl")
            ncx_xsl_file = os.path.join( os.path.dirname( __file__ ),"mets2ncx.xsl")
            mets_doc = etree.parse(self.work.get_mets_document())
            opf_xsl = etree.XSLT(etree.parse(opf_xsl_file))
            opf_doc = opf_xsl(mets_doc)
            ncx_xsl = etree.XSLT(etree.parse(ncx_xsl_file))
            ncx_doc = ncx_xsl(mets_doc)
            self.opf = etree.tostring(opf_doc, encoding="utf-8", pretty_print=True)
            self.ncx = etree.tostring(ncx_doc, encoding="utf-8", pretty_print=True)
        return (self.opf, self.ncx)
    
    meta = property(_meta)
    
    def get_container(self):
        f = open( os.path.join( os.path.dirname(__file__), "container.xml"), "r")
        data = f.read()
        f.close()
        return data
        
    def __call__(self, output=None):
        if hasattr(output,'write'):
            output.write( self.get_zip_data() )
        else:
            return self.get_zip_data()
        

    def write_meta(self, zip):
        containerinfo = zipfile.ZipInfo("META-INF/container.xml")
        containerinfo.compress_type = zipfile.ZIP_DEFLATED
        contdata = self.get_container()
        zip.writestr(containerinfo, contdata )
        opf, ncx = self.meta
        opfinfo = zipfile.ZipInfo("OPS/book.opf")
        opfinfo.compress_type = zipfile.ZIP_DEFLATED
        zip.writestr(opfinfo, opf)
        ncxinfo = zipfile.ZipInfo("OPS/toc.ncx")
        ncxinfo.compress_type = zipfile.ZIP_DEFLATED
        zip.writestr(ncxinfo,ncx)
        
    def wrap_html(self,filepath):
        absfile = os.path.abspath(filepath)
        XHTML_NS = "http://www.w3.org/1999/xhtml" 
        XHTML = "{%s}" % XHTML_NS
        page_title = absfile in self.section_map and self.section_map[absfile].title or 'Chapter Title'
        ctx = etree.iterparse(filepath)
        html = etree.Element(XHTML + "html", nsmap={None: XHTML_NS })
        head = etree.SubElement(html, XHTML + "head")
        title = etree.SubElement(head, XHTML + 'title')
        title.text = page_title
        body = etree.SubElement(html,XHTML + "body")
        # regexes to undo what was done on ingest
        wustrip = re.compile(r"\{\{[^\}]+\}\}")
        ssr = re.compile(r"\{% url[^,]+,\s*(\d+)\s*%\}")

        for action, el in ctx:
            if el.tag == 'img':
                srcatt = el.attrib.get('src', '')
                nv = wustrip.sub("", srcatt)
                el.attrib['src'] = nv
            if el.tag == 'a':
                href = ssr.sub(lambda x: "%03d-segment.html" % int(x.group(1)) , el.attrib.get('href', ''))
                el.attrib['href'] = href
            el.tag = XHTML + el.tag
            
        
        body.append(ctx.root)
        return etree.tostring(html)
            
            
        
                
    def copy_content(self, zip):
        wd = os.path.abspath(self.work.get_content_directory())
        for root,dirs,files in os.walk(wd):
                for filename in files:
                    if os.path.splitext(filename)[-1] in CONTENT_EXTENSIONS:
                        absfile = os.path.join(root,filename)
                        targetpath = "OPS/content/" + absfile[len(wd)+1:]
                        if targetpath.endswith(".html"):
                            htmldata = self.wrap_html(absfile)
                            cinfo = zipfile.ZipInfo(targetpath)
                            zip.writestr(cinfo,htmldata)
                        else:
                            zip.write(absfile,targetpath,zipfile.ZIP_DEFLATED)

    def get_zip_data(self):
        io = StringIO()
        zf = zipfile.ZipFile(io,"w")
        # note by default this does ZIP_STORED; if you want compression, you 
        # need to manually create a ZipInfo object first
        zf.writestr("mimetype", EPUB_MIMETYPE)
        self.write_meta(zf)
        self.copy_content(zf)
        zf.close()
        return io.getvalue()









