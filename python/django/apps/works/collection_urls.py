from django.conf.urls.defaults import *
from conf import settings

import views

urlpatterns = patterns('',
    url(r"^/?$", views.collection_index, name="collection_index"),
    url(r"^index", views.collection_index, name="collection_index"),
    url(r"^(?P<id>\d+)/?$", views.collection_by_id, name="collection_by_id"),
    url(r"^(?P<slug>[a-zA-Z\-0-9]+)/?$", views.collection_by_slug, name="collection_by_slug"),
    url(r"^(?P<slug>[a-zA-Z\-0-9]+)/browse/?$", views.collection_browse, {'browse_by': 'alphabetical'}),    
    url(r"^(?P<slug>[a-zA-Z\-0-9]+)/browse/(?P<browse_by>[a-zA-Z]+)/?$", views.collection_browse, name="collection_browse"),    
    url(r"^(?P<slug>[a-zA-Z\-0-9]+)/introduction/?$", views.collection_introduction, name="collection_introduction"),
    url(r"^(?P<slug>[a-zA-Z\-0-9]+)/about/?$", views.collection_about, name="collection_about"),
    url(r"^(?P<slug>[a-zA-Z\-0-9]+)/about/staff/?$", views.collection_about_staff, name="collection_about_staff"),    
)