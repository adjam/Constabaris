#!/usr/bin/env python

__doc__ = """Runs various sanity checks on an ingest package, including making sure all referenced images are available and that all internal links successfully resolve.""" 

import os, sys
from lxml import etree
from PIL import Image

import logging

log = logging.getLogger("ingest.validator")

class Validator(object):
    """Base class for validators."""

    def __init__(self,archive, *args, **kwargs):
        """Required Parameters:
`archive` : an IngestArchive object"""
        self.archive = archive
        self.has_run = False
        self.errors = []
        self.warnings = []

    def cleanup(self):
        """Validation runs should call this after the validator is no longer needed, to free memory and other open resources"""
        pass

    def is_valid(self):
        """Always returns False, so you have to override it."""
        return False

class HTMLValidator(Validator):
    
    def __init__(self,archive,*args,**kwargs):
        super(HTMLValidator,self).__init__(archive, *args, **kwargs)
        self.has_run = False
        
    def get_evaluators(self):
        if not hasattr(self, 'evaluators'):
            evals = {}
            for fn in self.get_html_files():
                doc = etree.parse( self.archive.get_file(fn) )
                key = os.path.split(fn)[-1]
                evals[key] = (doc, etree.XPathEvaluator(doc, namespaces={'x': 'http://www.w3.org/1999/xhtml'}), fn )
                self.evaluators = evals
        return self.evaluators

    def get_html_files(self):
        if not hasattr(self, 'html_files'):
            self.html_files = [ x for x in self.archive.get_entries() if x.endswith(".html") ]
        return self.html_files
    
class ImageValidator(HTMLValidator):
    
    IMG_PREFIX = "@work_media_url@"
    
    WARN_WIDTH = 640
    
    WARN_HEIGHT = 860
    
    def get_image_files(self):
        if not hasattr(self, 'image_files'):
            imgexts = ('.jpg', '.png', '.gif', '.svg', '.jp2',)
            self.image_files = [ x for x in self.archive.get_entries() if os.path.splitext(x.lower())[-1] in imgexts ]
        return self.image_files
    
    def is_valid(self):
        if not self.has_run:
            images = self.get_image_files()
            for imgpath in images:
                img = Image.open(self.archive.get_file(imgpath))
                width,height = img.size
                log.debug("Image %s dimensions (%d, %d)" % ( imgpath, width, height) )
                if ( width > ImageValidator.WARN_WIDTH ):
                    self.warnings.append("Image %s is very wide (%d px, recommended maximum %d)" % (imgpath, width, ImageValidator.WARN_WIDTH) )
                if ( height > ImageValidator.WARN_HEIGHT ):
                    self.warnings.append("Image %s is very tall (%d px, recommended maximum %d)" % (imgpath, height, ImageValidator.WARN_HEIGHT) )

            for fn in self.get_evaluators():
                warns, errors = self.check_image_paths(fn)
                self.warnings.extend(warns)
                self.errors.extend(errors)
            self.has_run = True
        return len(self.errors) == 0
    
    def resolve_path(self,filepath,refval):
        parts = os.path.split(filepath)[:-1]
        base = os.path.join(*parts)
        return os.path.join(base, refval)
        
    
    def check_image_paths(self,filename):
        doc, ev, zip_path = self.get_evaluators()[filename]
        warns = []
        errors = []
        for href in ev("//x:img/@src"):
            if href.startswith(ImageValidator.IMG_PREFIX):
                path = href[len(ImageValidator.IMG_PREFIX):]
                imgpath = self.resolve_path(zip_path,path)
                if not imgpath in self.get_image_files():
                    errors.append("Image %s may have been found" % path)
        return ( warns, errors )
                

class InternalLinkValidator(HTMLValidator):
    """Verfies that all links in a package's HTML files derived from links in the original TEI document
    resolve to the proper out HTML file."""

    #def __init__(self, archive,*args,**kwargs):
    #    super(InternalLinkValidator,self).__init__(archive,*args,**kwargs)
    #    self.has_run = False
    
    def is_valid(self):
        if self.has_run:
            return len(self.errors) == 0
        self.get_evaluators()
        for htmlfile in self.get_html_files():
            header, failures = self.check_file(htmlfile)
            if len(failures):
                for f in failures:
                    self.errors.append(f)
        self.has_run = True
        return len(self.errors) == 0
        
    def verify_link(self,hrefval):
        if '-segment' in hrefval:
            fn, id = hrefval.split("#", 1)
            if not fn in self.evaluators:
                return False
            ev = self.evaluators[fn][1]
            tgt = ev("//*[@id='%s']" % id)
            return len(tgt) == 1
        return True
    
    def check_file(self,filename):
        file_key = os.path.split(filename)[-1]
        ev = self.evaluators[file_key][1]
        hrefs = [ x.attrib.get('href') for x in ev("//x:a") ]
        header = "%s : %d links" % ( filename, len(hrefs) )
        failures = []
        for url in hrefs:
            if not self.verify_link(url):
                failures.append("%s" % url)	
        return header, failures




if __name__ == '__main__':
    dirs = sys.argv[1:2]
    directory = dirs and dirs[0] or "."
    print "Checking files in ", directory
    files = get_files(directory)
    evs = get_evaluators(files,directory)
    for filename in files:
        header, failures= check_file(filename,evs)
        print header
        if not failures:
            print "\tAll links resolve"
        for fail in failures:
            print "\t", fail
        print "----"




