import haystack
import haystack.indexes as indexes
import haystack.sites as sites

import utils

from tagging.models import Tag

import os

import models
import logging

log = logging.getLogger("work.indexes")

def get_index_id(obj):
    return haystack.utils.get_identifier(obj)
    #return u"%s.%d" % ( obj.__class__.__name__.lower(), obj.pk )

def get_authors(work):
    authorings = models.WorkAuthoring.objects.filter(work=work)
    if authorings:
        return [ x.author.display_name for x in authorings ]
    return None


class WorkIndex(indexes.RealTimeSearchIndex):
    id = indexes.CharField()
    url = indexes.CharField()
    parentId = indexes.CharField(null=True)
    collection = indexes.CharField(default='lcrm')
    genre = indexes.CharField(model_attr='genre__label')
    title = indexes.CharField(model_attr='title')
    titleSort = indexes.CharField()
    subtitle = indexes.CharField(model_attr='subtitle',null=True)
    description = indexes.CharField(model_attr='description')
    lcsh = indexes.MultiValueField(null=True)
    tags = indexes.MultiValueField(null=True)
    isbn = indexes.CharField(model_attr='isbn',null=True)
    publishedYear = indexes.IntegerField(null=True)
    publisher = indexes.CharField(model_attr='publisher__name',null=True)
    author = indexes.MultiValueField(null=True)

    # note: that default is true does not imply that by default, works are
    # open access; just that the work itself should come up if it matches a
    # search
    open_access = indexes.BooleanField(default=True)
    created = indexes.DateField(model_attr='created')
    text = indexes.CharField(document=True)
    timestamp = indexes.DateTimeField(model_attr="last_modified")

    # optional fields below
    # note these probably mess up schema generation ..
    rights_t = indexes.CharField(null=True)
    doi_t = indexes.CharField(model_attr='doi',null=True)
    
    def get_updated_field(self):
        return 'last_modified'
    
    def update_object(self,instance,**kwargs):
        if not instance.available:
            self.remove_object(instance)
        else:
            log.debug("Updating '%s'" % self.prepare_id(instance) )
            super(WorkIndex,self).update_object(instance, **kwargs)

        si = SectionIndex(models.Section)
        for sect in instance.section_set.all():
            si.update_object(sect)

    def prepare_id(self,obj):
        return get_index_id(obj)

    def prepare_url(self,obj):
        return obj.get_absolute_url()

    def prepare_parentId(self,obj):
        if obj.parent is not None:
            return self.prepare_id(obj.parent)
        return None

    def prepare_titleSort(self,obj):
        return obj.title.lower()

    def prepare_description(self,obj):
        if obj.description:
            return utils.html_to_text( obj.description )
        return None

    def prepare_lcsh(self,obj):
        subjs = obj.subjects.all()
        if subjs:
            return [ x.label for x in subjs ]
        return None

    def prepare_tags(self,obj):
        tags = Tag.objects.get_for_object(obj)
        if tags:
            return [ x.name for x in tags ]
        return None

    def prepare_publishedYear(self,obj):
        if obj.published is not None:
            return obj.published.year
        return None

    def prepare_author(self,obj):
        return get_authors(obj)

    def prepare_text(self,obj):
        return "%s %s %s" % ( obj.title, self.prepare_author(obj), self.prepare_description(obj) )

    def get_queryset(self):
        return models.Work.objects.filter(available=True)

class SectionIndex(indexes.RealTimeSearchIndex):
    id = indexes.CharField()
    url = indexes.CharField()
    parentId = indexes.CharField(null=True)
    collection = indexes.CharField(default='lcrm')
    genre = indexes.CharField(default='Section')
    title = indexes.CharField(model_attr='title')
    titleSort = indexes.CharField()
    subtitle = indexes.CharField(model_attr='work__title',null=True)
    description = indexes.CharField(null=True)
    lcsh = indexes.MultiValueField(null=True)
    tags = indexes.MultiValueField(null=True)
    isbn = indexes.CharField(null=True)
    publishedYear = indexes.IntegerField(null=True)
    publisher = indexes.CharField(null=True)
    author = indexes.MultiValueField(null=True)

    open_access = indexes.BooleanField(model_attr="access_controlled")
    created = indexes.DateField(model_attr='work__created')
    text = indexes.CharField(document=True)
    timestamp = indexes.DateTimeField(model_attr="last_modified")

    page_start_i = indexes.IntegerField(model_attr="start_page")
    page_end_i = indexes.IntegerField(model_attr="end_page")
    
    def get_updated_field(self):
        return 'last_modified'
    
    # we override this because we want sections for works that are not
    # available to be removed from the index, even though that's just
    # a standard 
    def update_object(self,instance, **kwargs):
        if not instance.work.available:
            log.debug("removing section [%d] of work [%d] because work is not available" % ( instance.pk, instance.work.pk ) )
            self.remove_object(instance)
        else:
            super(SectionIndex,self).update_object(instance,**kwargs)
    
    #def should_update(self,instance,**kwargs):
    #    try:
    #        return instance.work.available
    #    except AttributeError:
    #        return false

    def prepare_id(self,obj):
        return get_index_id(obj)
    
    def prepare_url(self,obj):
        return obj.get_absolute_url()

    def prepare_created(self,obj):
        return obj.work.created

    def prepare_parentId(self,obj):
        return get_index_id(obj.work)

    def prepare_tags(self,obj):
        tags = Tag.objects.get_for_object(obj)
        if tags:
            return [ x.name for x in tags ]
        return None

    def prepare_author(self,obj):
        return get_authors(obj.work)

    def prepare_open_access(self,obj):
        return not obj.access_controlled

    def prepare_text(self,obj):
        if os.path.exists(obj.get_filename()):
            handle = open(obj.get_filename())
            txt = utils.xml_to_text(handle)
            handle.close()
            return txt
        return None

    def get_queryset(self):
        return models.Section.objects.filter(work__available=True)

print models.__file__
sites.site.register(models.Work,WorkIndex)
sites.site.register(models.Section,SectionIndex)
