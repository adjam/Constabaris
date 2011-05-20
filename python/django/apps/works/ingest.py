#!/usr/bin/env python

# -*- coding: utf-8 -*-

import zipfile
import os
import shutil
import re
from cdla.xmlmodels.mets import METSDocument
from cdla.xmlmodels.tei import TEIDocument
from cdla import util as cdlautil
from lxml import etree
from datetime import datetime
from django.db import transaction
from django.template.defaultfilters import slugify
import codecs
from cStringIO import StringIO

import utils as works_utils

from conf import settings

import models

from cdla.images import utils as imageutils
from tagging.models import Tag

import logging

log = logging.getLogger("works.ingest")

def relpath(path,start="."):
    if hasattr(os.path, 'relpath'):
        return os.path.relpath(path,start)
    start_parts = os.path.abspath(start).split(os.path.sep)
    path_parts = os.path.abspath(path).split(os.path.sep)
    i = len(os.path.commonprefix([ start_parts, path_parts ]))
    elements = [ os.path.pardir ] * ( len(start_parts)-i ) + path_parts[i:]
    if not elements:
        return ""
    return os.path.join(*elements)

re_caps = re.compile(r"([A-Z])")
def camel_case_to_words(text):
    parts = re_caps.split(text)[1:]
    if len(parts) == 3:
        return text
    blocks = map("".join, zip(parts[::2],parts[1::2]))
    return " ".join(blocks)

class LineFilter(object):
    """
    Encapsulates a regular expression replacement routine.
    """
    def __init__(self,regex,replacement):
        """
        Creates a new filter that replaces all matches of the supplied regex
        with the supplied replacement, which may either be a static string 
        (or unicode object) or a callable function.
        
        The returned object is callable; if that seems mysterious, one can
        explicitly call the `filter` method.
        
        Arguments:
        `regex` : a compile regular expression object
        
        `replacement` : either a static string/unicode object or a function
        that accepts a single regular expression match object as argument.
        
        e.g. 
        `LineFilter(re.compile(r"(Boys)", "Girls"))` -- results in a filter
        that replaces each occurence of "Boys" in strings to "Girls".
        
        `LineFilter(re.compile(r"(Boys)", lambda x : x.group(1).upper())` -- results
        in a filter that replaces each occurence of "Boys" in a string with "BOYS".
        """
        self.regex = regex
        self.replacement = replacement
        self.filter = self.__call__
        
    def __call__(self,line):
        return self.regex.sub(self.replacement,line)
    
# TODO: I don't like that code in _commit_sections where the HTML
# gets "massaged" and it might be a good idea to break it out.
class HTMLFilter(object):
    def __init__(self,work):
        self.work = work
        self.filters = []
        
        # order is important!
        self.filters.append(LineFilter(re.compile(r"""\s+xmlns=(['"])http://www.w3.org/1999/xhtml\1""",re.U), u""))

        def section_url_replacer(m):
            return u"{%% url works:section '%s',%d %%}" % ( self.work.slug, int(m.group(1)) )

        self.filters.append(LineFilter(re.compile(r"(\d+)-segment.html", re.U), section_url_replacer))
        self.filters.append(LineFilter(re.compile(r"@work_media_url@",re.U), u"{{ work.media_url }}"))
        self.filters.append(LineFilter(re.compile(r"@image_not_available@",re.U), settings.MISSING_IMAGE_URL))
        
    def __call__(self,line):
        for filt in self.filters:
            line = filt(line)
        return line
        
    
class Image(object):
    def __init__(self,archive,href,mimetype):
        self.archive = archive
        self.href = href
        self.name = os.path.basename(href)
        self.mimetype = mimetype
        self.exists = archive.contains_entry(href)

    def _create_thumbnail(self):
        data = self.archive.get_file(self.href)
        img = imageutils.read_image(data)
        thumb = imageutils.get_thumbnail(img,size=(128,128))
        data_uri = imageutils.get_data_url(thumb)
        self.data_uri = data_uri
        return data_uri

    def thumbnail(self):
        """
        Gets the image's data in thumbnail size as a data URI
        """
        return getattr(self,'data_uri', self._create_thumbnail())

def unique_slug(model,slug_field,slug_value):
    orig_slug = slug = slugify(slug_value)
    index = 0
    while True:
        try:
            model.objects.get(**{slug_field: slug})
            index +=1
            slug = orig_slug + "-" + str(index)
        except model.DoesNotExist:
            return slug



class IngestArchive(object):
    """
    A wrapper around an ingest package that allows easy access to files in the package
    """
    def __init__(self,zip_path):
        self.file_path = zip_path
        self.zip = zipfile.ZipFile(zip_path, "r")
        
    def get_entries(self):
        return self.zip.namelist()

    def get_mets(self):
        """
        Gets a file-like object for the METS document in the archive
        """
        return self.get_file("mets.xml")

    def get_tei(self):
        """
        Gets a file-like object reading the TEI document in the archive
        """
        return self.get_file("tei.xml")

    def get_file(self,path):
        """
        Gets a file-like object reading a document stored at
        the supplied path within the archive.
        """
        if hasattr(self.zip, 'open'): # 2.6
            return self.zip.open(path)
        return StringIO(self.zip.read(path))

    def get_cover_image(self):
        """
        Gets a 2-tuple (file-like object, file basename) of the cover image 
        contained in the ingest archive, e.g. (fl reader, 'cover.png')
        or (None, None,) if no cover image is found in the archive.
        """
        base = "content/cover.%s"
        for ext in ("jpg","png","svg","gif"):
            filename = base % ext
            if filename in self.zip.namelist():
                    return ( self.get_file(filename), os.path.basename(filename))
        return (None,None,)
    
    def contains_entry(self, entry_name):
        """
        Tests whether a given path maps to an entry in the zip file.
        This is useful to e.g. check that a referenced image file is
        in the archive.
        """
        try:
            entry = self.zip.getinfo(entry_name)
            return True
        except KeyError:
            return False

    def __del__(self):
        if hasattr(self,'zip'):
            self.zip.close()
        sup = super(IngestArchive,self)
        if hasattr(sup, '__del__'):
            sup.__del__()

class IngestContext(object):
    """
    Bridge between ingest packages and XML models.
    """
    def __init__(self, archive, **kwargs):
        if hasattr(archive, 'get_mets'):
            self.archive = archive
        else:
            self.archive = IngestArchive(archive)
        self._mets_file = self.archive.get_mets()
        self._tei_file =  self.archive.get_tei()        
        self.extra_args = kwargs
        if 'license' in kwargs:
            self.license = kwargs['license']
        

    def to_document(self,file):
        """Gets an lxml.etree document from a file-like-object"""
        return etree.parse(file)

    def _get_mets_document(self):
        if not hasattr(self,'_mets'):
            doc = self.to_document(self._mets_file)
            self._mets = METSDocument(doc)
        return self._mets
    mets = property(_get_mets_document)

    def _get_tei_document(self):
        if not hasattr(self,'_tei'):
            doc = self.to_document(self._tei_file)
            self._tei = TEIDocument(doc)
        return self._tei
    tei = property(_get_tei_document)

    def _get_segments(self):
        return self.mets.segments
    segments = property(_get_segments)

    def _get_media(self):
        return self.mets.media
    media = property(_get_media)


class IngestAction(object):
    """Instances of this class drive the ingest process with the help
    of an IngestContext.  The result of executing this action is
    the creation of a new work and any ancillary objects (sections,
    publishers, etc.).
    """

    def __init__(self,context):
        self.context = context
        self.format = None

    def get_default_cover(self):
        thisfile = os.path.abspath(__file__)
        default_cover = os.path.join( os.path.dirname(thisfile), "fixtures/cover-missing.jpg")
        f = open(default_cover, "r")
        return (f,"cover.jpg")


    def get_publisher(self,meta):
        """
        Gets the publisher metadata as a Publisher model object.
        If the publisher has not previously been seen, returned object's
        `pk` attribute will be `None`
        """
        name = meta.publisherName
        place = meta.publisherPlace
        try:
            return models.Publisher.objects.get(name=name,location=place)
        except models.Publisher.DoesNotExist:
            return models.Publisher(name=name,location=place)
        

    def get_subjects(self,meta):
        """
        Gets a list of subjects found in the metadata, while querying the
        database to ensure that previously seen subjects are returned instead of
        new objects.  The 'freshness' of each resuting object can be tested by
        looking at the `pk` attribute, which will be `None` for subjects not previously
        seen.
        """
        mgr = models.Subject.objects
        result = []
        for subj in meta.subjects:
            try:
                model_sub = mgr.get(label=subj)
            except models.Subject.DoesNotExist:
                model_sub=models.Subject(label=subj)
            result.append(model_sub)
        return result

    def get_authors(self,meta):
        """Gets a list of NamedPerson objects corresponding to the authors
        found in the meta parameter.  Each returned result can be checked
        for 'newness' by checking its ``pk`` attribute against None
        """
        mgr = models.NamedPerson.objects
        result = []
        for auth in meta.authors:
            try:
                model_auth = mgr.get(reg_form=auth.reg_form)
            except models.NamedPerson.DoesNotExist:
                fresh = True
                model_auth = models.NamedPerson(display_name=auth.display_form,reg_form = auth.reg_form)
            model_auth.editor = auth.editor
            result.append(model_auth)
        return result

    def get_keywords(self):
        tei = self.context.tei
        return [ x for x in tei.get_keywords() ]
        
    def get_links(self):
        """
        Returns a list of ExternalURL objects extracted from 
        the TEI document's header.
        see `xmlmodels.tei.TEIDocument` for more info
        """
        tei = self.context.tei
        rv = []
        for link in tei.get_links():
            url = models.ExternalURL(description=link['label'], value=link['href'])
            rv.append(url)
        return rv
            

    def get_sections(self):
        """
        Gets the sections defined in the context, adding the foreign key reference
        to the supplied work.
        Result is a sequence of 2-tuples consisting of an unsaved Section and the section metadata.
        """
        divs = self.context.mets.segments
        sections = []
        work = self.work
        for div in divs:
            filename_order = int(div.file.filename[:3])
            sect = models.Section(work=work,title=div.title,order=filename_order,source_id=div.source_id)
            sect.filename = div.file.filename
            sect.start_page = div.page_start
            sect.end_page = div.page_end
            if hasattr(div,'page_number_style'):
                if div.page_number_style == "roman":
                    sect.page_number_style = 1
                else:
                    sect.page_number_style = 2
            else:
                sect.page_number_style = 3
            sections.append((sect, div))
        sections.sort( lambda x,y : cmp(x[0].order, y[0].order) )
        #fmt = getattr(work,"format", None)
        #if fmt is None:
            #if len(sections) == 0:
                #work.format = models.Format.objects.get(label="Container")
            #elif len(sections) == 1:
                #work.format = models.Format.objects.get(label="Single Page")
            #else:
                #work.format = models.Format.objects.get(label="Multiple Pages")
        return sections

    def copy_text_file(self,arc_path, destpath, line_filter=lambda x: x):
        input = self.context.archive.get_file(arc_path)
        base = os.path.dirname(destpath)
        if not os.path.isdir(base):
            os.makedirs(base)
        output = codecs.open(destpath, "w", "utf-8")
        for line in input:
            uline = unicode(line, "utf-8")
            output.write(line_filter(uline))
        output.close()
        input.close()

    def _commit_sections(self,sections):
        if not hasattr(self,'work'):
            raise AttributeError("commit_sections called before Work was initialized.  This is a programming error.")
        if self.work.pk is None: 
            raise AttributeError("commit_sections called with unsaved Work.  This is a programming error")
        archive = self.context.archive
        dest_dir = self.work.get_content_directory()
        filt = HTMLFilter(self.work)
        work_media_url = self.work.get_media_url()
        smgr = models.Section.objects
        for sect, div in sections:
            try:
                fromdb = smgr.get(work=self.work,order=sect.order)
                fromdb.title = sect.title
                fromdb.source_id = sect.source_id
                sect = fromdb
            except models.Section.DoesNotExist:
                sect.work = self.work
            sect.save()
            self.copy_text_file(div.file.path, sect.get_filename(), line_filter=filt)

    def _copy_media_file(self,source,dest_path):
        """
        Copies (the contents of) a file-like object to a certain path
        in the work's content directory.
        """
        output = os.path.join(self.destbase,dest_path)
        if not os.path.isdir( os.path.dirname(output) ):
            os.makedirs(os.path.dirname(output))
        dest = open(output,"wb")
        shutil.copyfileobj(source,dest)

    def _get_destbase(self):
        if not hasattr(self,'work'):
            raise AttributeError("Unable to locate destination because we haven't created a new work object yet")
        if not hasattr(self, '_destbase'):
            self._destbase = self.work.get_content_directory()
        return self._destbase
    destbase = property(_get_destbase)

    def _write_media(self):
        archive = self.context.archive
        for image in self.media:
            if image.exists:
                f = image.href
                rel = relpath(f, "content")
                dest_path = os.path.join( self.destbase, os.path.dirname(rel))
                if not os.path.isdir(dest_path):
                    os.makedirs(dest_path)
                try:
                    source = archive.get_file(f)
                    dest = open(os.path.join(dest_path, os.path.basename(rel)), "wb")
                    shutil.copyfileobj(source,dest)
                    source.close()
                    dest.close()
                except KeyError, k:
                    log.warn("file %s in METS but not in archive" % f)
        cover,covername = archive.get_cover_image()
        if cover is None and self.work.genre.label== u'Book':
            cover,covername = self.get_default_cover()

        if cover is not None:
            self._copy_media_file(cover,covername)

    def _write_meta(self, formats=['mets', 'tei']):
        """
        Writes ingested TEI and METS files to the work's content
        directory.
        """
        mets = self.context.mets
        tei = self.context.tei
        output_dir = self.work.get_content_directory()
        if 'tei' in formats:
            f = open( os.path.join( output_dir, "tei.xml"), "w")
            f.write( etree.tostring(tei.doc,encoding="utf-8",
                                    xml_declaration=True) )
            f.close()
        if 'mets' in formats:
            f = open( os.path.join( output_dir, "mets.xml"), "w")
            f.write( etree.tostring(mets.doc,
                                    pretty_print=True,
                                    encoding="utf-8",
                                    xml_declaration=True) )
            f.close()
        
    def overwrite_content(self,work):
        """
        Updates only TEI, METS, the HTML for sections contained in an ingest package.
        """
        assert work.pk is not None
        warnings, errors = works_utils.validate_ingest_package(self.context.archive)
        self.work = work
        sections = self.get_sections()
        self._commit_sections(sections)
        self._write_meta()
        return { 'work' : work, 'sections' : sections, 'warnings' : warnings, 'errors' : errors }
    
    def find_genre(self,label):
        genre_tried = [camel_case_to_words(label), label, 'Book']
        rv = None
        for gt in genre_tried:
            if rv is None:
                try:
                    rv = models.Genre.objects.get(label=gt)
                except models.Genre.DoesNotExist:
                    pass
        
        if rv is None:
            raise Exception("Unable to find correct genre, tried '%r'", genre_tried)
        return rv

        

    def execute(self,work=None,commit=False):
        """
        Executes the action.  
        Keyword parameters:
        `work` : the work to be modified.  If one is not supplied, a new one will
        be created.
        `commit` : whether to save anything to the database and filesystem.
        """
        archive = self.context.archive
        meta = self.context.mets.metadata
        tei = self.context.tei
        
        warnings,errors = works_utils.validate_ingest_package(self.context.archive)
        
        if work is None:
            work = models.Work()
            

        work.license = getattr(self.context, 'license', models.License.objects.all()[0])
        work.genre = self.find_genre(meta.genre_name)
        
        work.title = meta.title
        work.slug = unique_slug(models.Work, 'slug', meta.title)
        work.subtitle=meta.subtitle and meta.subtitle or ""
        authors = self.get_authors(meta)
        editors = [ x for x in authors if x.editor ]
        author_names = [ x.display_name for x in authors ]
        auth_display = works_utils.get_text_list(author_names, "and")
        
        if len(editors) > 0:
            auth_display += ", Editor"
            if len(editors) > 1:
                auth_display += "s"
            
            
        work.author_display = auth_display
        
        try:
            work.description = tei.get_abstract_html()
        except Exception:
            work.description = meta.description
            
        work.page_count = self.context.tei.page_count()
        self.work = work
        publisher = self.get_publisher(meta)
        if meta.isbn is not None:
            work.isbn = meta.isbn
            if not work.isbn.isdigit():
                dre = re.compile(r"^\s*(\d+)")
                m = dre.search(work.isbn)
                if m:
                    work.isbn = m.group(1)
                else:
                    work.isbn = None

        if hasattr(meta, 'doi') and meta.doi is not None:
            work.doi = meta.doi

        if 'publishedYear' in meta:
            pubYear = int(meta.publishedYear)
            work.published = datetime(pubYear,1,1)

        subjects = self.get_subjects(meta)
        sections = self.get_sections()
        work.license = models.License.objects.all()[0]
        self.media = [ Image(archive,m['href'], m['mimetype']) for m in self.context.mets.media ]
        links = self.get_links()
        
        keywords = self.get_keywords()

        if commit:
            for s in subjects:
                if s.pk is None:
                    s.save()
            if publisher.pk is None:
                publisher.save()
            work.publisher = publisher
            kwstring = ",".join(keywords)
            work.tags = kwstring
            work.save()

            for s in subjects:
                work.subjects.add(s)

            for a in authors:
                if a.pk is None:
                    a.save()
                authoring = models.WorkAuthoring(work=work,author=a)
                authoring.save()
            work.save()
            
            for link in links:
                link.content_object = work
                link.save()
            self._commit_sections(sections)
            self._write_media()
            self._write_meta()
            archive_path = archive.file_path
            shutil.copyfile( archive.file_path, os.path.join(work.get_content_directory(), "ingest.zip") )


        ctx = { 'work' : work,
            'sections' : sections,
            'authors' : authors,
            'media' : self.media,
            'subjects' : subjects,
            'keywords' : keywords,
            'publisher' : publisher,
            'links' : links,
            'saved' : commit,
            'warnings' : warnings,
            'errors' : 'errors'
            }
        return ctx

def _main(filename):
    context = IngestContext(filename)
    action = IngestAction(context)
    print action.execute(commit=True)

if __name__ == '__main__':
    import sys
    for file in sys.argv[1:]:
        _main(file)
