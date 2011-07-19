from django.conf.urls.defaults import *
from piston.resource import Resource
from apps.api.handlers import WorkHandler

works_handler = Resource(WorkHandler)

urlpatterns = patterns('',
    url(r'^work/(?P<work_id>[^/]\d+)/', works_handler),
    url(r'^work/(?P<data_view>[a-zA-Z_-]+)/(?P<work_id>\d+)/', works_handler),
    url(r'^work/(?P<data_view>[a-zA-Z_-]+)/', works_handler),
    url(r'^works/', works_handler),
)