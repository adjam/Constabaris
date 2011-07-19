from piston.handler import BaseHandler
from apps.works.models import Work, Section

import logging
log = logging.getLogger('api.handlers')


class WorkHandler(BaseHandler):
    allowed_methods = ('GET',)
    model = Work
    exclude = ('license','tags','genre', 'available',)
    data_views = {
        'base':  ('id', 'title', 'author_display', 'description', 'slug', 'publisher', 'doi', 'subtitle', 'parent', 'created', 'collection', 'last_modified', 'published', 'page_count', 'isbn', 'tei', 'mods', 'mets', 'section_list'),
        'preview': ('id', 'title', 'author_display', 'description', 'slug',),
        'tei': ('id', 'title', 'author_display', 'tei',),
        'mods': ('id', 'title', 'author_display', 'mods',),
        'mets': ('id', 'title', 'author_display', 'mets',),
        'section_list': ( 'id', 'title', 'author_display', 'section_list',),
        
        
    }

    @classmethod
    def tei(cls, work):
        return work.get_media_url() + 'tei.xml';

    @classmethod
    def mods(cls, work):
        return work.get_media_url() + 'mods.xml';

    @classmethod
    def mets(cls, work):
        return work.get_media_url() + 'mets.xml';

    @classmethod
    def section_list(cls, work):
        return work.get_sections_ordered();

    def read(self, request, work_id=None, data_view=None, filter=None):
        """
        Returns a single work if 'work_id' is given otherwise, a subset

        """
        base = Work.objects
        
        if data_view != None:
            try:
                self.fields = self.data_views[data_view]
            except KeyError:
                log.debug('unsupported data view')
        else:
            self.fields = self.data_views['base']
        
        if work_id:
            return base.get(pk=work_id)
        else:
            if filter:
                return base.filter(filter)
            else:
                return base.all()
                
class SectionHandler(BaseHandler):
    allowed_methods = ('GET',)
    model = Section
    fields = ('id', 'source_id', 'filename', 'media_url', 'start_page', 'end_page', 'order', 'last_modified')
    
    def read(self, request, section_id=None, data_view=None, filter=None):
        base = Sections.objects
        
        if data_view != None:
            try:
                self.fields = self.data_views[data_view]
            except KeyError:
                log.debug('unsupported data view')
        else:
            if filter:
                return base.filter(filter)
            else:
                return base.all()