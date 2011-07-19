from django.conf.urls.defaults import *
from conf import settings

import views

urlpatterns = patterns('',
    url(r"^$", views.index, {'template' : 'works/index.html'},name="index"),
    url(r"^doi/(?P<doi>.+)/?$", views.by_doi, name="bydoi"),
    url(r"^ingest/$",views.ingest,
            {'template' : 'works/ingest/form.html',
             'template_success' : 'works/ingest/verify.html'},
            name="ingest"),
    url(r"^ingest/commit/$", views.commit, {'template' : 'works/ingest/committed.html'} , name="commit"),
    url(r"^ingest/update/(?P<id>\d+)?", views.update, { 'template' : 'works/ingest/update.html'}, name="update"),
    url(r"^ingest/cleanup/?$", views.cleanup, name="admin_cleanup"),
    
    url(r"^browse/?$", views.browse, name="browse"),
    url(r"^unapi/?$", views.unapi, name="unapi"),

    url(r"^cite/(?P<slug>[a-zA-Z\-0-9]+)/?$", views.citation, name="citation"),
    url(r"^w/(?P<slug>[a-zA-Z\-0-9]+)/?$", views.by_slug, {'template' : 'works/work-main.html'}, name="byslug"),
    url(r"^w/(?P<slug>[a-zA-Z\-0-9]+)/s/(?P<order>\d+)/?$", views.section, {'template' : 'works/work-section.html'}, name="section"),
    url(r"^info/(?P<id>\d+)?/?", views.workinfo, name="work.info"),
    url(r"^searchinside/(?P<work_id>\d+)/?", views.search_in_work, name="search.inwork"),
    url(r"^errorsaplenty", views.error_out, name="cause_error"),
    
)
