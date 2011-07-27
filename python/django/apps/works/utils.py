import os
import shutil
import time
import tempfile
import urllib2
import zipfile
import logging
try:
    import hashlib
except ImportError:
    import md5 as hashlib

from django.utils import text
from django.utils.translation import ugettext_lazy

from lxml import etree,html
from cStringIO import StringIO

from cdla.util import citebuilder

import validator

from django.conf import settings as proj_settings

from conf import settings

from haystack.query import SearchQuerySet

import epub
from django.conf import settings
from django.core.exceptions import ObjectDoesNotExist
log = logging.getLogger('works.utils')

__doc__ = """
Contains various utilities for the 'works' application, mostly related to handling uploaded files and supplemental
content files.
"""

MAX_AGE = 60.0 * 5.0
"""
Maximum age of a file in seconds that will be removed when
clear_working_dir() is called.
"""

working_dir = os.path.join( tempfile.gettempdir(), "works-ingest")
if not os.path.isdir(working_dir):
    os.mkdir(working_dir)
    f = open( os.path.join(working_dir, "README") , "w")
    f.write("LCRM Django app stores uploads and ingest packages here.")
    f.close()

def file_hash(filename):
    """
    Creates a hash of the specified filname (disregarding directory information);
    this is used by the ingest process to mask the actual filename.  See also
    find_upload(key)
    """
    base = os.path.basename(filename)
    return hashlib.md5("s3krit-key" + base).hexdigest()

class UploadHandler(object):
    """
    Instances of this class handle the processing of files uploaded to the LCRM application.
    Uploaded content is written to a tempfile, which is then checked to see if it constitutes
    an ingest package; if not, the package is processed into an ingest package.
    @see PackageMaker
    """

    def __init__(self,uploadedFile):
        self.file = uploadedFile
        self.length = self.file.size
        self.mimetype = self.file.content_type

    def process(self):
        """
        Processes the uploaded file, including sending it off to
        the packaging application.
        Returns a tuple including
           - the filename indicating the ingestable package filename
           - the cryptographic key of said file
        side effects:
           - creating the ingestable package (if needed)
           - setting filename and file_key attributes
        """
        ext = os.path.splitext(self.file.name)[-1]
        fd, filename = tempfile.mkstemp(prefix="lcrm-upload-", suffix=ext,dir=working_dir)
        for chunk in self.file.chunks():
            os.write(fd, chunk)
        os.close(fd)
        self.filename = filename
        self.packager = PackageMaker(self.filename)
        if not self.packager.is_ingestable:
            rv = self.packager.get_package()
            os.unlink(self.filename)
            self.filename = rv
        self.file_key = file_hash(self.filename)
        return self.filename, self.file_key

class PackageMaker(object):
    """
    Provides functions for testing files to see if they constitute ingest packages, and for sending them
    on for processing if not.
    """

    def __init__(self,input_file):
        """
        input_file: path to a zip that may or may not be directly ingestable.

        When this method is called, sets the attribute is_ingestable indicating
        whether or not the zip file requires further processing.
        """
        self.input_file = input_file
        self.is_ingestable = PackageMaker.is_ingest_package(input_file)

    def is_ingest_package(filename):
            """
            Static method that checks a zip file to see if it's an ingest package.
            Currently this amounts to seeing if it contains a file called mets.xml at the
            root of the zip.
            """
            zip = zipfile.ZipFile(filename,"r")
            try:
                mets = zip.getinfo("mets.xml")
                zip.close()
                return True
            except KeyError, k:
                # no mets.xml, so we presumably don't have an ingest package
                return False
    is_ingest_package = staticmethod(is_ingest_package)


    def get_package(self):
        """
        Gets the filename of the ingestable package, which may be the original input file.
        @see is_ingest_package
        """
        if hasattr(self,'package_file'):
            return self.package_file
        if self.is_ingestable:
            return self.input_file
        data = ""
        try:
            post_url = settings.PACKAGER_SERVICE_URL
            log.debug("Basic ingest package detected, posting to %s" % post_url)
            req = urllib2.Request(post_url)
            req.add_header("Content-Type", "application/zip")
            fh = open(self.input_file, "r")
            data = fh.read()
            fh.close()
        except IOError,ioe:
            print post_url
            # fixme -- the service is probably unavailable, and we should let the user know that
            raise Exception("The packager service is unavailable.  Please upload a processed ingest package or try later.")

        try:
            req.add_data(data)
            req.add_header('Content-Length', len(data))
            handle = urllib2.urlopen(req)
            # API changed between 2.4 and 2.6; somewhat after 2.4, 'handle.code' became handle.getcode()
            response_code = getattr(handle, 'getcode', handle.code)
            if response_code == 200:
                fd, filename = tempfile.mkstemp(prefix="lcrm-package-", suffix=".zip",dir=working_dir)
                os.write(fd, handle.read())
                os.close(fd)
                handle.close()
            else:
                response = handle.read()
                handle.close()
                raise IOError("Packager service was unable to process your input: " + response)
            self.package_file = filename
        except IOError, ioe:
            raise ioe
        #
        return self.package_file

def recreate_ingest_package(work):
    """
    Attempts to re-create an ingest package based on the files in a work's content directory.
    This can be used for administrative purposes, or on delete to save a version of the work
    for diagnostic purposes.
    Returns the location of a zip file containing the ingest package.
    """
    wd = work.get_content_directory()
    location = tempfile.mkstemp(suffix='.zip')[1]
    package = zipfile.ZipFile(location, "w", zipfile.ZIP_DEFLATED)
    for f in ("mets.xml", "tei.xml"):
        package.write( os.path.join(wd, f), f )
    html_files = [ f for f in os.listdir(wd) if f.endswith(".html") ]
    for f in html_files:
        package.write( os.path.join(wd,f), "content/" + f)
    for f in os.listdir(os.path.join(wd, "figures")):
        package.write( os.path.join(wd, "figures", f), "content/figures/" + f)
    package.close()
    return location

def validate_ingest_package(archive):
    """
    Runs validation routines on an ingest.IngestArchive object.
    Currently these results are treated as purely advisory.
    Returns a tuple of dicts indicating warnings and errors
    encountered during validation.
    """
    warnings = {}
    errors = {}
    htmlval = validator.InternalLinkValidator(archive)
    linksvalid = htmlval.is_valid()
    warnings['internal links'] = htmlval.warnings
    if not linksvalid:
        errors['internal links'] = htmlval.errors
    imgval = validator.ImageValidator(archive)
    imgval.evaluators = htmlval.get_evaluators()
    imgvalid = imgval.is_valid()
    warnings['Images'] = imgval.warnings
    if not imgvalid:
        errors['Images'] = imgval.errors
    
    return (warnings, errors)
    
def movefile(source,dest):
    if os.path.isdir(dest):
        dest = os.path.join(dest, os.path.basename(source) )
    shutil.move(source,dest)

def delete_files(workdir):
    log.info("Delete files called on %s" % workdir )
    wd = os.path.abspath(workdir)
    base_dir = os.path.abspath(proj_settings.MEDIA_ROOT, "works")
    if not os.path.isdir(wd):
        log.warn("%s is not a directory, so not deleting" % wd)
        return
    if not wd.startswith(base_dir):
        log.warn("%s is outside managed content tree %s; not deleting" % ( wd, base_dir ))
        return
    shutil.rmtree(wd)
    log.info("rmtree complete on %s" % wd)

def find_upload(file_key):
    """
    Locates an uploaded file in the current upload directory
    by its key.  Note that this routine is not optimized and hence
    clear_working_dir() should be called occasionally to clean up
    said directory.
    """
    for filename in os.listdir(working_dir):
        full_name = os.path.join(working_dir,filename)
        if file_hash(full_name) == file_key:
            return full_name

# serial comma, darnit
def get_text_list(seq_,last_word=ugettext_lazy(u"or")):
    """
    Overrides get_text_list() from django.contrib.text
    so that it outputs a serial ("Oxford") comma instead
    of what those heretical *newspaper* people do.
    """
    if len(seq_) <= 2:
            return text.get_text_list(seq_,last_word)
    else:
        bits = []
        bits.extend(seq_[:-1])
        bits.append(last_word)
        return ", ".join(bits) + " " + seq_[-1]

def clear_working_dir():
    now = time.time()
    for temp_file in os.listdir(working_dir):
        if temp_file != "README":
            fp = os.path.join(working_dir, temp_file)
            if now - os.path.getctime(fp) > MAX_AGE:
                os.unlink(fp)

def flatten(l):
    if isinstance(l,(list,tuple,)):
        return sum(map(flatten,l))
    return l

def html_to_text(hstr):
    """Extracts the text content between elements in an HTML string.
    Returns a normalized string suitable for indexing"""
    doc = html.fromstring(hstr)
    txt = " ".join( [ x.text for x in doc.iter() if x.text ])
    return " ".join( txt.split() ) # normalizes the text

def xml_to_text(xstr,exclude_inline_footnotes=True):
    """Extracts the text content between elements in an XML string or file-like
    object.
    Returns a normalized string suitable for indexing.
    Arguments:
    `xstr`: a string or file-like object containing XML
    `exclude_inline_footnotes`: whether the contents of inline footnotes should
    be removed from the document before extracting its text; this helps prevent false-ish
    positives for search queries that match inline note text, which in some sense is not
    part of the document in which it occurs (e.g. CSS will usually hide it by default)."""
    if hasattr(xstr,'read'):
        doc = etree.parse(xstr)
    else:
        doc = etree.XML(xstr)
    if exclude_inline_footnotes:
        inlines = doc.xpath("//span[contains(@class,'inline-note')]")
        for note in inlines:
            if note.getparent() is not None:
                note.getparent().remove(note)
        
    txt = " ".join( doc.xpath("//text()"))
    return " ".join( txt.split() )

def get_mods(work):
    modspath = os.path.join(work.get_content_directory(), "mods.xml")
    if not os.path.exists(modspath):
        ns = {'mods': "http://www.loc.gov/mods/v3"}
        log.debug("MODS record not found for '%s', creating in %s" % ( work.title, modspath))
        metspath = os.path.join(work.get_content_directory(), "mets.xml")
        mets = etree.parse(metspath)
        mods = mets.xpath("//mods:mods[1]", namespaces=ns)[0]
        h = open(modspath, "w")
        h.write(etree.tostring(mods, pretty_print=True,xml_declaration=True, encoding="utf-8"))
        h.close()
    f = open(modspath, "r")
    data = f.read()
    f.close()
    return data

def get_epub_path(work):
    """Gets the path to the epub version of this work, creating the file if it doesn't yet exist"""
    epubfile = os.path.join( work.get_content_directory(), "work.epub")
    if not os.path.exists( epubfile ):
        
        log.info("Creating epub for %r [%d]" % ( work, work.pk ))
        try:
            pack = epub.Packager(work)
            out = open(epubfile,"w")
            pack(out)
            out.close()
        except Exception, e:
            log.error("Unable to create epub", exc_info=True)
            os.unlink(epubfile)
            raise
    return epubfile

def build_cite_dict(work):
    info = { 'title' : work.title,
             'publisher' : work.publisher.name,
             'location' : work.publisher.location,
             'year' : work.published.strftime("%Y"),
             'pages' : work.page_count}
    auths = work.workauthoring_set.all()
    for authnum,authing in enumerate(auths):
        if authnum < 3:
            name = authing.author.display_name
            prefix = authing.is_editor and "editor" or "author"
            bits = name.split(" ", 3)
            num = authnum + 1
            info['%sfname%d' % ( prefix, num)] = bits[0]
            if len(bits) == 2:
                info['%slname%d' %( prefix,num)] = bits[1]
            elif len(bits) == 3:
                info['%smname%d' % ( prefix,num) ] = bits[1][0]
                info['%slname%d' % ( prefix,num) ] = bits[2]

    return info

def get_citation(work):
    info = build_cite_dict(work)

    cs = ('mlastyle', 'chicago-bib',)

    results = citebuilder.get_citation(info,styles=cs)
    if not results:
        mlafmt = "%d %b. %Y"
        import time
        d = { 'author' : work.author_display,
              'title' : work.title,
              'pubDate' : work.published.strftime(mlafmt),
              'today' : time.strftime(mlafmt),
              'url' : work.get_absolute_url() }
        return u"""<dl>
<dt>MLA (Web)</dt>
 <dd>%(author)s. "%(title)s."</dd>
 <dd><i>Publishing the Long Civil Rights Movement: Works, Comments, and Links</i>. %(pubDate)s.  Web
 %(today)s</dd>
 <dd>&lt;https://lcrm.lib.unc.edu%(url)s&gt;</dd>
</dl>""" % d

    else:
        rv = u"<dl>"
        for idx, style in enumerate(results):
            sname = citebuilder.STYLES[cs[idx]]['display_name']
            rv += u"<dt class='citation-style'>%s</dt>" % ( sname )
            rv += u"<dd>%s</dd>" % unicode(style)

        rv += u"</dl>"
        return rv
    return u"<ul>\n".join(results)

def get_section_source(section):
    sourcefile = os.path.join( section.work.get_content_directory(), "tei.xml")
    doc = etree.parse(sourcefile)
    sect_source = doc.xpath("//*[@xml:id = '%s']" % section.source_id )[0]
    return etree.tostring(sect_source, pretty_print=True)

#import pysolr
class SidebarBuilder(object):
    facets = {}
    def __init__(self):
        try:
            for facet in settings.BROWSE_BY_FACETS:
                log.debug(facet)
                facet_list = self._get_facet_group(facet)
                if len(facet_list) > 0:
                    self.facets[facet] = facet_list
        except Exception, e:
            log.warn("Solr apparently unavailable:%r" % e)
            self.facets = [('browsing currently unavailable', 0,)]
            
    def _get_facet_group(self, facet_field):
        search_query_set = SearchQuerySet().filter(django_ct='works.work').facet(facet_field)
        facets = []
        for x in search_query_set.facet_counts()['fields'][facet_field]:
            facets.append({'name': x[0], 'count': x[1]})
            
        return facets        

    def get_collections(self):
        from models import Collection
        collections = []
        search_query_set = SearchQuerySet().filter(django_ct='works.work').facet('collection')
        for x in search_query_set.facet_counts()['fields']['collection']:
            try:
                collections.append({'collection': Collection.objects.get(name=x[0]), 'count': x[1]})
            except ObjectDoesNotExist:
                log.debug(x[0]+' collection does not exist')
        return collections

    def get_facets(self):
        return self.facets        