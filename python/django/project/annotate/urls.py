from django.conf.urls.defaults import *
from django.contrib import admin
admin.autodiscover()
from django.conf import settings
import registration

from django.views.generic.simple import redirect_to
from django.views.generic.simple import direct_to_template

from apps.works.views import WorkSearchView

import registration
import django.contrib.auth.views as authviews

handler500 = 'apps.works.views.server_error'

urlpatterns = patterns('',
    url(r'^$', redirect_to, { 'permanent' : True, 'url' : 'works/' }),
    url(r'^notes/', include('apps.notes.urls'),),
    url(r'^works/', include('apps.works.urls', app_name="works", namespace="works")),
    url(r'^collections/', include('apps.works.collection_urls', namespace="collections")),
    url(r'^tinymce/', include('tinymce.urls')),
    url(r'^accounts/profile/(?P<profile_id>\d+)?/?$', 'apps.works.views.profile', name="user.profile"),
    url(r'^accounts/register/complete/?',direct_to_template, {'template': 'registration/registration_complete.html'}, name="registration_complete"),
    url(r'^accounts/activate/complete/?',direct_to_template, {'template': 'registration/activation_complete.html'}, name="activation_complete"),
    url(r'^accounts/', include('registration.urls', app_name="registration")), #registration urls for the older version of django registration
    # url(r'^accounts/', include('registration.backends.default.urls')), #registration urls for the new version of django registration
    url(r'^search/advanced/', 'apps.works.views.advanced_search', name="advanced-search"),
    url(r'^search/', WorkSearchView(), name="search"),
    # include('haystack.urls', app_name="search", namespace="search")),
    url(r'api/', include('apps.api.urls', namespace="api")),

    # Uncomment the admin/doc line below and add 'django.contrib.admindocs'
    # to INSTALLED_APPS to enable admin documentation:
    (r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    (r'^admin/', include(admin.site.urls)),
    
)

urlpatterns += patterns('django.contrib.flatpages.views',
    url(r'about/$', 'flatpage', { 'url' : '/about/' }, name="about"),
    url(r'terms/$', 'flatpage', { 'url' : '/terms/' }, name="terms"),
    url(r'privacy/$', 'flatpage', { 'url' : '/privacy/' }, name="privacy"),
    url(r'contact/$', 'flatpage', { 'url' : '/contact/' }, name="contact"),
    url(r'faq/$', 'flatpage', { 'url' : '/faq/' }, name="faq"),
    url(r'guidelines/$', 'flatpage', { 'url' : '/guidelines/' }, name="guidelines"),
)

if settings.DEBUG:
    urlpatterns += (
        url(r'^voice/static/(?P<path>.*)$', 'django.views.static.serve', { 'document_root' : settings.MEDIA_ROOT}, name="site.media"),
    url(r'^medea/(?P<path>.*)$', 'django.views.static.serve', { 'document_root' : 'static_content', 'show_indexes' : True }, name="static.media"),
    
        )
