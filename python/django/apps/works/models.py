from django.db import models

try:
    import tagging
    from tagging.fields import TagField
    HAS_TAGGING = True
except ImportError:
    HAS_TAGGING = False

from django.template.defaultfilters import slugify
from django.conf import settings
import os, datetime, urlparse
from cdla.util import isbntools, roman
import utils
import django.contrib.auth.models as authmodels
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes import generic
from django.db import connection
from django.core.urlresolvers import reverse
from django.contrib.sites.models import Site 
from django.contrib.flatpages.models import FlatPage
import re

from cdla.images.utils import get_thumbnail

from tinymce import models as tinymce_models

import logging

log = logging.getLogger("works.models")

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


class AutoSlugField(models.SlugField):
    def pre_save(self,model_instance,add):
        if self.prepopulate_from:
            if self.unique:
                return unique_slug(model_instance.__class__, self.name, getattr(model_instance, self.prepopulate_from[0]))
            else:
                return slugify(getattr(model_instance,self.prepopulate_from[0]))
        else:
            return super(AutoSlugField,self).pre_save(model_instance,add)

class Contact(models.Model):
    """
    A named entity that has basic contact info
    """
    first_name = models.CharField(max_length=128)
    last_name = models.CharField(max_length=128)
    email = models.EmailField(null=True,blank=True)

class Subject(models.Model):
    """
    A subject heading.
    """
    label = models.CharField(max_length=128)
    uri = models.CharField(max_length=512,
                   null=True,
                   blank=True,
                   help_text="The URI for the subject in a controlled vocabulary (if any)")

    def __unicode__(self):
        if self.uri is not None:
            return u"Subject: %s {%s}" % ( self.label, self.uri )
        else:
            return u"Subject: %s" % ( self.label )

class Publisher(models.Model):
    name = models.CharField(max_length=512)
    location = models.CharField(max_length=256,
                    help_text="(usually) the municipality in which the publisher is located for bibliographic purposes")
    address = models.TextField(blank=True,help_text="The mailing address for the publisher")
    contact = models.ForeignKey(Contact,null=True,blank=True)

    def __unicode__(self):
        return u"%s, %s" % ( self.name, self.location )


class License(models.Model):
    """
    A license governing how the work may be used, as distinct from information about
    the copyright holder.
    """
    name = models.CharField(max_length=128,unique=True)
    description = models.TextField()
    reference_url = models.URLField(max_length=512,blank=True,help_text="A URL at which more information about the license can be found")

    def __unicode__(self):
        return self.name

class Genre(models.Model):
    """
    A classification of the work that it falls under in virtue of its
    content; e.g.

    the EPrints refinements to the DCMI Type Vocabulary
    serve as a good start for the models here.
    see http://www.ukoln.ac.uk/repositories/digirep/index/Eprints_Type_Vocabulary_Encoding_Scheme
    Potentially, differences in genre could entail different modes of presentation,
    although there are no provisions for doing so yet.
    """
    label = models.CharField(max_length=128,unique=True,help_text="A user-friendly description of the genre")
    uri = models.URLField(max_length=255,unique=True,help_text="Value for the Dublin Core 'Type' element",editable=False)
    enabled = models.BooleanField(default=False,help_text="Whether this genre can be selected at ingest time")
    citation_style = models.CharField(max_length=128, choices=(('book', 'Book'),('web', 'Web'),('none', 'None'),), help_text="How citations for this work should be formatted")
    description = models.TextField()

    def __unicode__(self):
        return self.label

class Collection(models.Model):
    name = models.CharField(max_length=128,unique=True,help_text="A user friendly name")
    description = models.TextField(blank=True,help_text="A full description for the collection landing page")
    blurb = models.TextField(blank=True, default='A collection of resources', help_text="A blurb for a collection list page")
    slug = models.SlugField(max_length=255,unique=True)

    def save(self, *args, **kwargs):
        log.debug('works.models.Collection.save()')
        if not self.id:
            log.debug('--saving a new collection')
            from django.contrib.sites.models import Site
            site = Site.objects.get(id=1)
            #if it's a new collection set up the flatpage stubs and the media directory
            about = FlatPage.objects.create(url=self.url_base+'/about/', title=self.name+" - About")
            about.sites.add(1)
            about.save()
            intro = FlatPage.objects.create(url=self.url_base+'/introduction/', title=self.name+" - Introduction")
            intro.sites.add(1)
            intro.save()
            staff = FlatPage.objects.create(url=self.url_base+'/about/staff/', title=self.name+" - About - Staff")
            staff.sites.add(1)
            staff.save()

            try:
                os.makedirs(self.media_url)
            except OSError as (errno, strerror):
                if errno == 17:
                    pass
                else:
                    raise
        else:
            # Update collection name would need to update the url of the pages
            last_saved = Collection.objects.get(id=self.id)
            if self.slug != last_saved.slug:
                log.debug('slug has changed******')
                for fp in FlatPage.objects.filter(url__startswith='/collections/'+last_saved.slug):
                    log.debug('changing flatpage urls ******')
                    new_url = re.sub(last_saved.slug, self.slug, fp.url)
                    fp.url = new_url
                    fp.save()

                try:
                    log.debug('renamed the media directory')
                    os.rename(os.path.join(settings.MEDIA_ROOT, "collections", str(last_saved.slug)), self.media_url)
                    log.debug('renamed the media directory')
                except OSError as (errno, strerror):
                    log.debug('OSError found')
                    if errno == 2:
                        log.debug('OSError == 2')
                        if os.path.exists(self.media_url):
                            log.debug(self.media+" already exists")
                            pass
                        else:
                            os.makedirs(self.media_url)
                    else:
                        raise
        
        super(Collection, self).save(*args, **kwargs)
        # Delete would delete the default flatpages, or all flatpages
        
    def delete(self, *args, **kwargs):
        log.debug('works.models.Collection.delete')
        # delete flatpages
        FlatPage.objects.filter(url__startswith=self.url_base).delete()

        # delete media directory
        log.debug(self.media_url)
        try:
            os.removedirs(self.media_url)
        except OSError as (errno, strerror):
            if errno == 2:
                pass
            else:
                raise

        # set collection_id for all works in collection to null
        Work.objects.filter(collection=self.id).update(collection="")
        super(Collection, self).delete(*args, **kwargs)

    @models.permalink
    def get_absolute_url(self):
        return ('collections:collection_by_slug', (), {'slug': self.slug})
    
    def _get_works(self):
        return Work.objects.filter(collection=self.id).order_by('title')
    works_list = property(_get_works)
    
    def _get_media_url(self):
        return os.path.join(settings.MEDIA_ROOT, "collections", str(self.slug) )
    media_url = property(_get_media_url)
    
    def _get_url_base(self):
        return '/collections/'+self.slug
    url_base = property(_get_url_base)
            
    def _get_collection_pages(self):
        return FlatPage.objects.filter(url__startswith="/collections/"+self.slug)
    flatpages = property(_get_collection_pages)

    def get_page(self, page_name):
        return self.url_base+'/'+page_name

    def __unicode__(self):
        return self.name
    

class Work(models.Model):
    """
    A coherent unit of content.  May have one or more sections.
    """
    #format = models.ForeignKey(Format,blank=True,null=True)
    genre = models.ForeignKey(Genre)
    parent = models.ForeignKey('Work',blank=True,null=True)
    license = models.ForeignKey(License)
    title = models.CharField(max_length=256)
    available = models.BooleanField(default=False,
                    help_text="Whether the work is available for viewing")
    slug = models.SlugField(max_length=255,unique=True)
    isbn = models.CharField(max_length=13,null=True,blank=True)
    doi = models.CharField(max_length=512,
                   verbose_name="DOI",
                   blank=True,
                   null=True,
                   help_text="Digital Object Identifier")
    subtitle = models.CharField(max_length=512,blank=True)
    description = tinymce_models.HTMLField(help_text="A short description or abstract")
    author_display = models.CharField(max_length=512, help_text="The author name(s) as it should appear in text")
    publisher = models.ForeignKey(Publisher,blank=True,null=True)
    extent = models.CharField(max_length=128,blank=True)
    created = models.DateTimeField(editable=False)
    published = models.DateField(blank=True,null=True)
    subjects = models.ManyToManyField(Subject, blank=True,null=True)
    tags = TagField(max_length=1024)
    links = generic.GenericRelation('ExternalURL')
    last_modified=models.DateTimeField(editable=False,auto_now=True,auto_now_add=True)
    rights = models.TextField(blank=True,help_text="Information about the holder of the copyright")
    page_count = models.IntegerField(default=-1)
    collection = models.ForeignKey(Collection, blank=True,null=True)
    site = models.ForeignKey(Site, blank=True, null=True, default="1")
    
    def save(self, *args, **kwargs):
        if not self.id:
            self.created = datetime.datetime.now()
        self.last_modified = datetime.datetime.now()
        super(Work,self).save(*args, **kwargs)
        
    def _label(self):
        return u"%s [%d]" % ( self.title[:30], self.pk )
    
    label = property(_label)

    def __unicode__(self):
        return u"%s - %s [%r]" % ( self.title, self.author_display, self.pk )

    def get_isbn_display(self):
        return isbntools.format(self.isbn)

    def get_author_cite(self):
        words = self.author_display.split()
        return "%s, %s" % ( words[-1], " ".join(words[:-1]) )

    def get_content_directory(self):
        return os.path.join(settings.MEDIA_ROOT, "works", str(self.id) )

    def get_sections_ordered(self):
        return self.section_set.order_by("order")
    
    def get_media_url(self):
        try :
            return urlparse.urljoin(settings.MEDIA_URL, "works/%d/" % (self.id,))
        except Exception, e:
            log.warn("Encountered error trying to create media_url: %r" % e)
    media_url = property(get_media_url)
            
    def paginated(self):
        return self.page_count > 0

    def get_cover_image(self):
        if os.path.exists( os.path.join(self.get_content_directory(),"cover.jpg") ):
            return os.path.join(self.get_media_url(), "cover.jpg")
    
    def get_mets_document(self):
        return os.path.join(self.get_content_directory(), "mets.xml")

    def get_source_document(self):
        return os.path.join(self.get_content_directory(), "tei.xml")
    
    def is_citable(self):
        return self.genre.citation_style is not None and self.genre.citation_style != "none"
        
    def get_comment_count(self):
        from notes.models import Annotation
        return Annotation.objects.filter(work=self, approved_date__isnull=False).count()
    comment_count = property(get_comment_count)

    @models.permalink
    def get_absolute_url(self):
        return ('works:byslug', (), {'slug': self.slug})
        
    def delete(self):
        content_dir = self.get_content_directory()
        log.info("Delete called on work [%d]" % self.id)
        saved_id = self.id # delete() unsets the ID attribute, which we need in order to clear out the directory
        super(Work, self).delete()
        fname = "saved-work-%d.zip" % saved_id
        self.id = saved_id
        if hasattr(settings, "ATTIC"):
            try:
                target = os.path.join(settings.ATTIC, fname)
                log.info("Saving work to %s" % target)
                archive = utils.recreate_ingest_package(self)
                utils.movefile(archive,target)
            except OSError, ose:
                log.error("Error encountered saving deleted work (id:%s) to %s: %r" % ( saved_id, target, ose))
        else:
            log.info("Cleaning up %s" % (self.get_content_directory()))
        try:
            utils.delete_files(content_dir)
        except Exception, e:
            log.exception("unable to delete %s: %r" % ( content_dir, e ) )
    
            
# this was an example of an image upload field that would automatically save a thumbnail of 
# the uploaded image.  It works, but it's not needed here.

##class ThumbnailImageField(models.ImageField):
##    """
##    Subclass of standard ImageField that automatically thumbnails the incoming image.
##    """
##    def __init__(self,*args,**kwargs):
##        md = kwargs.get('max_dimension', 64)
##        if not isinstance(md, int):
##            md = 64
##        if md <= 0:
##            raise ValueError("max_dimension must be > 0")
##        self.max_dimension = md
##        if 'max_dimension' in kwargs : del kwargs['max_dimension']
##        super(ThumbnailImageField,self).__init__(*args,**kwargs)
##        
##        
##    
##    def save_form_data(self,instance,data):
##        from cStringIO import StringIO
##        from PIL import Image
##        from django.core.files.uploadedfile import SimpleUploadedFile,UploadedFile
##        if data and isinstance(data,UploadedFile):
##            img = Image.open(data)
##            thumb = get_thumbnail(img,max_dimension=self.max_dimension)
##            thumbdata = StringIO()
##            thumb.save(thumbdata,img.format)
##            data = SimpleUploadedFile(data.name,thumbdata.getvalue(),data.content_type)
##        super(ThumbnailImageField,self).save_form_data(instance,data)
        
    

class FeaturedWork(models.Model):
    """Represents a work that should show up on the front page and be displayed in some special manner"""
    work = models.ForeignKey(Work, unique=True)
    blurb = models.CharField(max_length=512)
    date_added = models.DateTimeField(auto_now_add=True)
    
    def __unicode__(self):
        return u"Featured: %s [%d]" % ( self.work.title, self.work.id )
    

class BlogEntry(models.Model):
    """Site news announcement."""
    class Meta:
        ordering = ("-created",)
        verbose_name = "Site Update"
        
    title = models.CharField(max_length=128)
    created = models.DateTimeField(auto_now_add=True,editable=False)
    updated = models.DateTimeField(auto_now=True,null=True,editable=False)
    content = models.TextField()
    tags = TagField()
    creator = models.ForeignKey(authmodels.User)

    def __unicode__(self):
        post_id = self.pk is None and -1 or self.pk
        return u"Blog Entry<%d>: %s %s" % (post_id, self.title, self.created)

class ExternalURL(models.Model):
    """
    An external link associated with a model object,
    e.g.
    a URL for purchasing the print copy, etc.
    """
    value = models.URLField(max_length=256,verbose_name="URL")
    description = models.CharField(max_length=128,verbose_name="The link text")
    content_type = models.ForeignKey(ContentType)
    content_object= generic.GenericForeignKey('content_type', 'object_id')
    object_id = models.PositiveIntegerField()
    created_time = models.DateTimeField(auto_now_add=True,editable=False)

    def __unicode__(self):
        ct = self.content_type
        ct_label = u"%s.%s" % ( ct.app_label, ct.name )
        co = self.content_object
        co_label = "%s [deleted]" % ct_label
        if co is not None:
            co_label = u"%s:[%r]" % ( ct_label, co.pk )
        return u"Link: %s => %s" % ( co_label, self.description )

class Section(models.Model):
    """
    A chapter, section, or other portion of a Work that will be displayed on a single page.
    """
    class Meta:
        ordering = ['work', 'order']
        unique_together = (('work', 'order'),)
        permissions = (
            ("can_view_restricted", "Can see access-controlled sections"),

            )
    order = models.IntegerField()
    work = models.ForeignKey(Work)
    title = models.CharField(max_length=256)
    filename = models.CharField(max_length=256, help_text="Name of the file containing the pre-transformed HTML",editable=False)
    source_id = models.CharField(max_length=512, help_text="The id or XPath of the element in the source XML from which this section's content is derived")
    access_controlled = models.BooleanField(default=True,help_text="Can all users access this content?")
    accepts_comments = models.BooleanField(help_text="Will new comments be accepted for this section?",default=True)
    shows_comments = models.BooleanField(help_text="Will existing comments be shown on this section?",default=True)
    last_modified = models.DateTimeField(editable=False, auto_now_add=True,auto_now=True)
    start_page = models.IntegerField(default=-1)
    end_page = models.IntegerField(default=-1)
    page_number_style = models.IntegerField(choices=((1,'Front Matter'),(2,'Body'), (3, 'Unnumbered'),))

    def get_filename(self):
        return os.path.join(self.work.get_content_directory(),self.filename)

    def get_media_url(self):
        try :
            log.debug(self.work.media_url)
            return urlparse.urljoin(self.work.media_url, "%s" % (self.filename))
        except Exception, e:
            log.warn("Encountered error trying to create media_url: %r" % e)
    media_url = property(get_media_url)
    
    def has_page_numbers(self):
        return self.start_page > 0 and self.end_page > 0

    @models.permalink
    def get_absolute_url(self):
        return ('works:section',(),{'slug':self.work.slug,'order':self.order})

    def page_range(self):
        """
        Gets the range of pages formatted correctly according to the style.
        """
        if self.page_number_style == 1:
            return map(roman.to_roman, (self.start_page,self.end_page))
        return (self.start_page,self.end_page)

    def get_comment_count(self):
        from notes.models import Annotation
        return Annotation.objects.filter(object_pk=self.id, approved_date__isnull=False).count()
    comment_count = property(get_comment_count)
    

    def __unicode__(self):
        return u"%s - [%d] %s" % (self.work.title,self.order,self.title)
        

class UserAccount(models.Model):
    """
    Represents a site member. This should be set as
    the profile object on django.contrib.auth.User
    """
    user = models.ForeignKey(authmodels.User,unique=True,editable=False)
    
    # this can be used to indicate that the user in question has been somewhow vetted, that
    # the name they are using really belongs to them.  
    verified = models.BooleanField(help_text="Has the identity of this person been verified by an administrator?", default=False)

    
    prior_approval = models.BooleanField(help_text="Has this member previously had comments approved?", default=False)

    # these fields are the ones under the user's control
    is_public = models.BooleanField(help_text="Show this user's profile page?",default=False)
    affiliation = models.CharField(max_length=256,null=True,blank=True,help_text="Where do you work?")
    about = models.CharField(max_length=256,blank=True,help_text="Who are you?")
    home_page = models.URLField(blank=True,help_text="A page about you")

    def get_display_name(self):
        return u"%s %s" % (self.user.first_name, self.user.last_name)

    def get_absolute_url(self):
        return ('user.profile', (), { 'profile_id': self.pk })

    get_absolute_url = models.permalink(get_absolute_url)

class NamedPerson(models.Model):
    """A person who may or may not be a user of a site, typically one that is associated with Works (i.e. an Author) and
    has a name whose form is subject to some sort of authority
    """
    display_name = models.CharField(max_length=128)
    reg_form = models.CharField(max_length=140,unique=True,help_text="Name of the person as it appears in some naming authority")
    user = models.ForeignKey('auth.user',null=True)

    def __unicode__(self):
        return self.display_name

class WorkAuthoring(models.Model):
    """
    An object representing the relationship between a work and its author(s).
    """
    class Meta:
        order_with_respect_to = 'work'
        verbose_name="Authoring"
        #unique_together = ('work', 'order',)

    work = models.ForeignKey(Work)
    is_editor = models.BooleanField(default=False)
    author = models.ForeignKey(NamedPerson)
    
    #order = models.PositiveIntegerField()

    def __unicode__(self):
        rel = self.is_editor and " [e]" or ""
        return u"%s%s- %s" % ( self.author.display_name, rel, self.work.title )
    


# add some signal handlers so that
# 1. a user profile is created when the authmodels.User object is
# created
# 2. when we're doing syncdb
# auto_now_add fields get handled properly; loading fixtures
# bypasses the save() method, which is where this normally
# gets handled

from django.db.models.signals import pre_save, post_save
try:
	from registration.signals import user_registered
except:
	log.debug('older version of registration')

def postsave_authuser(sender, instance, **kwargs):
    prof, new = UserAccount.objects.get_or_create(user=instance)

post_save.connect(postsave_authuser,sender=authmodels.User)

def presave_blogentry(sender,**kwargs):
    instance = kwargs['instance']
    print "presave_blogentry fired (%s)" % instance.pk
    if not instance.pk:
        print "Setting created on  %s" % ( unicode(instance) )
    instance.created = datetime.datetime.now()


# pre_save.connect(presave_blogentry,sender=BlogEntry)
# 
# def add_default_group(sender, **kwargs):
#     user = kwargs['user']
#     user.groups.add(authmodels.Group.objects.get(pk=settings.DEFAULT_USER_GROUP_ID))
# 
# user_registered.connect(add_default_group)
