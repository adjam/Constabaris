from django.db import models
from django.contrib.comments.models import Comment

import datetime
import time
import simplejson

from tagging.fields import TagField
from works.models import Work, Section
from datetime import datetime

def format_date(dt):
    return unicode(time.strftime("%Y-%m-%dT%T:%M:%SZ"))

# Create your models here.

class Format(models.Model):
    mimetype = models.CharField(max_length=128,unique=True)
    description = models.TextField(blank=True)

    def __unicode__(self):
        return u"format: %s" % self.mimetype

class Annotation(Comment):
    """
    Expanded Comment class that adds genres, formats, and pointers to
    parts of model objects that have internal structure (e.g. IDs or XPaths
    for XML/HTML objects, or areas of images.
    """

    class Meta:
        permissions = (
            ("can_moderate", "Can approve, edit, or remove annotations"),
        )
    title = models.CharField(max_length=128,null=True,blank=True)
    content_internal_path = models.CharField(max_length=512,null=True,blank=True,
                                             help_text="Picks out the part of the related object being annotated (e.g. id in HTML fragment, area in an image)")

    format = models.ForeignKey(Format, help_text="The format in which the annotation is stored")
    tags = TagField(max_length=512)
    genre = models.CharField(max_length=128,blank=True,help_text="The note's intended usage")
    approved_date = models.DateTimeField(blank=True,null=True,help_text="The date and time this note was approved", default=datetime.now())
    work = models.ForeignKey(Work, help_text="The work on which the comment was made.")

    def created_date(self):
        return self.submit_date

    @models.permalink
    def get_approval_url(self):
        return ("note.approve", (), { 'id' : self.pk }, )

    @models.permalink
    def get_absolute_url(self):
        return ("note.resource", (), { 'id' : self.pk },)
    
    def get_age_in_seconds(self):
        return (datetime.datetime.now() - self.created_date()).seconds
    
    def can_edit(self,user):
        if user and user.has_perm('notes.can_moderate'):
            return True
        if self.user == user and self.get_age_in_seconds() < settings.COMMENT_EDIT_GRACE_PERIOD:
            return True
        return False

    def approve(self):
        if self.user is not None:
            profile = self.user.get_profile()
            if profile is not None and hasattr(profile, 'prior_approval') and not profile.prior_approval:
                profile.prior_approval = True
                profile.save()
        self.is_public = True
        self.approved_date = datetime.datetime.now()
        self.save()
        
    def get_is_approved(self):
        if self.approved_date is None:
            return False
        else:
            return True

    def set_is_approved(self, val):
        if val:
            self.approve()
        else:
            self.approved_date = None
            self.save()

    is_approved = property(get_is_approved, set_is_approved)
    
    def get_section(self):
        return Section.objects.get(pk=self.object_pk)

    section = property(get_section)
        
            
            




