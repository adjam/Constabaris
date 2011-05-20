from django.conf.urls.defaults import *
from django.conf import settings
import views

urlpatterns = patterns('',
    url(r'^list/?$', views.list, name="note.list"),
	url(r'^create/$', views.create,name="note.create"),
	url(r'^(?P<id>\d+)/$', views.by_id, name="note.resource"),
	url(r'^(?P<id>\d+)/approve/?$', views.approve, name="note.approve"),
)

