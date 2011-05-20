********************
LCRM Django Project
********************

This is the Django "project" that binds together all of the Django
components.  My aim is to not reproduce the Django documentation, so
I'm not going to say much about how things work here, except to cover
details specific to this project.

Definitions
=============

:dfn:`Project Directory` is the directory where the project files
(e.g. ``settings.py``) live.

:dfn:`Apps Directory` is the root directory for the custom-written
Django apps used by this project.

:dfn:`Library Directory` is the place where python modules (either
custom developed or third-party) are typically installed.

:dfn:`Static Directory` is the place on the filesystem where the
static media files (CSS, images, Javascript) associated with the web
site are stored.

(it's true, there's no branching or tagging that has actually taken
place on the Constabaris SVN repository, **culpa mea**)

Dependencies
=============

Third Party Apps Used
----------------------

These have all been downloaded from their respective locations and
placed in the `Library Directory`.  

`django-registration
<http://bitbucket.org/ubernostrum/django-registration/>`_ -- handles
user self-registration, password resetting, etc.  Note that the
version in use here predates the versions available above -- ours was
downloaded from the old site at
http://code.google.com/p/django-registration/

`django-tagging <http://code.google.com/p/django-tagging/>`_ --
handles keywords on Works (and potentially comments, etc.)

`haystack <http://haystacksearch.org>`_ -- handles indexing and searching

`django-tinymce <http://code.google.com/p/django-tinymce/>`_ --
integrates TinyMCE rich editor into Django apps.  Frankly, I'm not all
that happy with this idea; PunyMCE might have been a better choice, or
something that integrates more smoothly with JQuery.

Third Party Python Modules
---------------------------

`lxml.etree <http://codespeak.net/lxml>`_ -- pythonic wrappers around
``libxml2`` and ``libxslt`` libraries, very fast, very powerful.

Custom Python Modules
----------------------

These are custom modules written for the project, but that may have
use outside of it and so have been installed alongside the third-party
Django apps:

``cdla.util.citebuilder`` -- Fetches formatted citations from Ben
Pennell's "Citation Builder" at
http://www.lib.unc.edu/house/citationbuilder/bookcitation.html

``cdla.util.isbntools`` -- functions for parsing, validating and
formatting 10 and 13 digit ISBNs.

``cdla.util.roman`` -- functions for converting roman numerals to
integers and vvice-versa.

``cdla.images.utils`` -- functions for resizing images, creating
thumbnails, and `Data URIs
<http://en.wikipedia.org/wiki/Data_URI_scheme>`_

``cdla.xmlmodels.mets`` and ``cdla.xmlmodels.tei`` -- allow for METS
and TEI (respectively) processing during ingest.

Custom Python Apps
====================

The ``notes`` and ``works`` apps are described in :doc:`apps/notes` and
:doc:`apps/works` respectively.  One thing to note about both
applications is that they use a per-application settings setup, in
that each app contains a :file:`conf/settings.py` file that sets
crucial variables for the application if they have not been set in the
*project*'s :file:`settings.py`.  This was done to promote
re-usability in these apps. 

Project Settings
=================

In general, most of the project settings you should ever have need to
configure are stored in the :file:`localSettings.py` file in the
project directory. This file should not be under version control (so
as to keep database passwords and server-specific configurations out
of it), but it is loaded by :file:`settings.py`.

A sample :file:`localSettings.py.tmpl` is in the project directory
under version control, and should be updated if new global project
settings are added.

(Django) App-specfic configurations are maintained in each app's
directory under :file:`conf/settings.py` -- the copies of those files
contain (hopefully) sensible default values for app-specific
attributes, which may be overridden by setting them in the *project's*
settings file (for all practical purposes, :file:`localSettings.py`!)





