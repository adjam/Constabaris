from django.conf.urls.defaults import *
from django.conf import settings
from notes import views

urlpatterns = patterns('',
	url(r'^form/$', views.show_form),
	url(r'^post/$', views.post_comment),
)

