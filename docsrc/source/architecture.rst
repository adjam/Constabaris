Architecture
*************

The application logic is primarliy handled by a `Django
<http://www.djangoproject.org>`_ project that makes use of several
redistributable applications, some of which were developed as part of
this project.  For the most part, this document assumes you have a
reasonable grasp of basic Django concepts, such as "apps", templates,
templatetags, views, and urlconfigs.

`works` - this application provides the guts of the operation; this
application stores and manages user account information, handles
metadata about the objects in the system, and also serves as the point
of entry to the search system.

`notes` - an extension to Django's `django.contrib.comments`
application, which allows the creation of comments that are related to
arbitrary model objects.  In particular it extends the basic
commenting framework by adding internal pointers, which allows
finer-grained relations than are supported by the basic comments app.
In addition, it exposes views that implement specific application
logic (e.g. only users with active accounts may post new comments).


Ingest
========

Ingest is done through the `works` app, at the URL `[site root]/works/ingest/`;
by default, ingest is only available to superusers.  The ingest screen is
designed to be as simple as possible, at the cost of putting the complexity of
ingest onto the person creating the ingest package.  The ingest process has a
submit-verify-confirm workflow, in that when a package is submitted, all the
model objects that would be created are created, and then a page is rendered to
the end user so s/he can verify that the submitted package was interpreted
correctly.  At that point, the user may confirm the package, at which point the
model objects will be created and inserted into the database.  In order to ease
some burden on the web server, the 'confirm' step is implemented using a
session variable, which is cleared after the ingest is complete.

If the user does not supply a complete *ingest package*, and the
project setting `PACKAGER_SERVICE_URL`` is specified, then the
application will submit the uploaded file to the ingest packager
service.

Packager Service
-----------------

This is a Java Servlet-based component that wraps an XML pipeline
(XProc) processor (based on XML Calabash, http://xmlcalabash.org).  It
is capable of operating in an 'interactive' mode or as a service
invoked over HTTP; the primary function of the application is to
process ZIP packages containing TEI P5 XML documents and the images
they reference into "ingest packages", which include the TEI, XHTML
fragments, and a METS document that serves as a manifest.

For more on this application, see :doc:`packager`





