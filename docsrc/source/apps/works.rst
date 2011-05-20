**************
The Works App
**************

This application is the heart of the project; most of the custom model
objects and logic are defined here, including the most heavily-used
views, searching customizations, and ingest.

The workhorse classes in this app are ``Work`` and ``Section``.  A
``Work`` instance represents any kind of standalone work with its own
metadata, e.g. a monograph, conference presentation, manual, report,
etc.  Each work has a content directory on the web server's
filesystem, under ``settings.MEDIA_ROOT/work/[work id]``, where its
TEI, METS, MODS, XHTML, and image files are stored.  As a convenience,
the ingest package is also stored here when it is uploaded and the
work is created.

Generally, a ``Section`` object corresponds directly to an XHTML
fragment, with the name [###]-segment.html, stored in the work's
content directory.  Any given Section may be individually marked as
open access or restricted access depending on the value of its
`access_controlled` attribute.

Other important model classes are mentioned in passing in the
:doc:`../metadata` document.

See :doc:`ingest` for more info about the (relatively complex)
ingest process.


Fixtures
=========

Initial setup of the database (basic admin user, default genres, etc.)
is driven by ``fixtures/initial_data.json`` file.  If you run
``./manage.py syncdb`` in the project directory these fixtures will be
loaded.

.. _dynamic-ssi:

Template Tags
===============

The ``templatetags/works.py`` file defines most of the custom tags
used by the app; there are ones for paginating results on searches and
browse lists, generating section lists (so that we don't show active
links for sections the current user does not have the privilege to
see, etc.)

Also of interest is the ``dynamicssi`` tag; at ingest, the standard
XHTML for each section is filtered to become a Django template.  This
is because we can't calculate the URL to any given work, section, or
referenced image until ingest is complete and IDs and slugs are
assigned.  So instead, we embed template text and, when the section
HTML is loaded, process it as a template.  The Django standard ``ssi``
tag does more of a classic "static" server side include, so this tag
embeds the logic needed to make it a dynamic include.  Note that
making all of this work requires doing some work in the project's
settings (specifically, setting the value of ``ALLOWED_MEDIA_ROOT``).

Templates
==========

Most of the app-specific templates are actually stored in the
``templates/works`` location under the project directory.  The one
exception is ``templates/tags/browse-genre.html``, which is used to
create the "browse by genre" list used on the sidebar and in the page
footer.

Special Features
=================

One of the Press' requirements was the ability to feature a specific
work on the front page; this is handled through the `FeaturedWork`
model class -- the most recently created one will be displayed on the
front page.

unAPI support 
--------------

The `unAPI standard <http://unapi.info/>`_ defines a discovery and
delivery mechanism for providing detailed metadata that certain
clients (such as Zotero) can harvest.  The basic mechanism here
piggybacks on the fact that MODS is used to transmit the bulk of the
metadata; when the MODS record for a given work is requested, it is
(lazily) extracted from the METS stored in the work's content
directory and delivered to the client.

ePub generation
----------------

It turns out that the standard format for an ingest package looks an
awful lot like an ePub file.  The logic for transforming the former
into the latter is embedded in the ``epub`` module in the app's
directory.  Currently, this code is written to basically reverse the
ingest process from the files on the system.  Note that it employs a
couple of XSLT files deployed into the :file:`epub` directory.
However, a better approach would be based off of the fact that after
this code was written, the app was made to store ingest packages into
the work's content directory.  A conversion based straight off of the
ingest packages would be safer.

Still another approach would be to
add the ability to convert ingest packages to ePub archives into the
packager webapp.

Ghosts of Previous Ideas
-------------------------

The basic infrastructure for creating blog posts with site updates was added,
although it's not currently active.

Custom Management Commands
==========================

A start was made on a few custom management commands, to allow cleanup
of deleted works, etc.  The code for these lives under
:file:`management/commands` in the app's directory.  In general the
name of the file in that directory is the name of the custom command,
e.g. :command:`manage.py static_cleanup` (executed in the project
directory) calls the code in
:file:`management/commands/static_cleanup.py`.  Note that with the
commands that manage the filesystem, when you execute the command
you're generally running as yourself, while the files you're
attempting to modify will be owned by the webserver process.  To make
that less of an issue, I mapped some of them to view functions only
accessible to administrative users to allow execution with the proper
permissions.

See `Writing custom django-admin commands
<http://docs.djangoproject.com/en/dev/howto/custom-management-commands/>`_
in the Django documentation for more info about the general topic.

Searching
==========

This facility deserves its own document, :doc:`searching`.




