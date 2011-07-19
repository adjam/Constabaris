# Django settings for annotate project.

# Find apps at same level as project
import sys
import os.path
import logging
import django

log = logging.getLogger("app.settings")


# most of the settings *should be* in localSettings.py
# see README and localSettings.py.tmpl if this file does not exist

try:
    from localSettings import *
except ImportError:
    log.warn("localSettings.py not found, application may not work.  Please see README")
    DATABASE_ENGINE = 'sqlite3' # 'postgresql_psycopg2', 'postgresql', 'mysql', 'sqlite3' or 'oracle'.
    DATABASE_NAME = 'works.db' # Or path to database file if using sqlite3.
    DATABASE_USER = ''             # Not used with sqlite3.
    DATABASE_PASSWORD = ''         # Not used with sqlite3.
    DATABASE_HOST = ''             # Set to empty string for localhost. Not used with sqlite3.
    DATABASE_PORT = ''             # Set to empty string for default. Not used with sqlite3.

# Local time zone for this installation. Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# If running in a Windows environment this must be set to the same as your
# system time zone.
TIME_ZONE = 'America/New_York'

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'en-us'

SITE_ID = 1

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = True

# depending on how your paths are set up, this might need to be different.

ROOT_URLCONF = 'urls'

# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.load_template_source',
    'django.template.loaders.app_directories.load_template_source',
#     'django.template.loaders.eggs.load_template_source',
)

MIDDLEWARE_CLASSES = (
    'django.middleware.common.CommonMiddleware',
    'django.contrib.csrf.middleware.CsrfViewMiddleware',
    'django.contrib.csrf.middleware.CsrfResponseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.middleware.transaction.TransactionMiddleware',
    # 'django.contrib.messages.middleware.MessageMiddleWare', investigate after Django 1.2 release
    #    'projects.lcrm.ProfileMiddleware',
    'django.contrib.flatpages.middleware.FlatpageFallbackMiddleware',
)

TEMPLATE_DIRS = (
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
   os.path.join(os.path.dirname(__file__), 'templates').replace('\\', '/'),
)

TEMPLATE_CONTEXT_PROCESSORS = (
    "django.core.context_processors.auth",
    "django.core.context_processors.debug",
    "django.core.context_processors.i18n",
    "django.core.context_processors.request",
    "django.core.context_processors.media"
)

INTERNAL_IPS = ('127.0.0.1',)


INSTALLED_APPS = (
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.sites',
    'django.contrib.flatpages',
    'django.contrib.comments',
    'django.contrib.admin',
    'django.contrib.webdesign',
    'tagging',
    'haystack',
    'tinymce',
    'registration',
    'piston',
    'notes',
    'works',
)

COMMENTS_APP = 'notes'

AUTH_PROFILE_MODULE = "works.UserAccount"

ACCOUNT_ACTIVATION_DAYS = 7

# LOGIN_REDIRECT_URL = SERVER_TYPE == 'mod_python' and "/voice/accounts/profile" or "/accounts/profile"
LOGIN_REDIRECT_URL = WEB_ROOT+"accounts/profile"

# Haystack configuration

HAYSTACK_SEARCH_ENGINE = 'solr'

HAYSTACK_SITECONF = 'haystack_sites'

# TinyMCE configuration

TINYMCE_DEFAULT_CONFIG = {
    "plugins" : "paste,searchreplace",
    "theme" : "advanced",
    "skin" : "o2k7",
    "convert_urls" : False,
    "theme_advanced_buttons1" : "bold,italic,bullist,numlist,link,separator,replace,separator,pasteword,cleanup,separator,code",
    "paste_auto_cleanup_on_paste" : False,
    "theme_advanced_buttons2" : "",
    # "theme_advanced_disable" : "underline,strikethrough,justifyleft,justifyright,justifycenter,justifyfull,outdent,indent,image,code,hr,fontselect,fontsizeselect,formatselect,styleselect,cleanup,sub,sup,forecolor,backcolor,visualaid,anchor,newdocument,undo,redo",
    "theme_advanced_toolbar_location" : "top",
    'debug' : False,
    "language" : 'en'
}

TINYMCE_SPELLCHECKER = False


SESSION_EXPIRE_AT_BROWSER_CLOSE=True

# Custom attributes

DATE_FORMAT="M d, Y"

DEFAULT_USER_GROUP_ID = 2
