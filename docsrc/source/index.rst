.. Constabaris documentation master file, created by
   sphinx-quickstart on Thu Feb 18 11:35:16 2010.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


Introduction
=============

This documentation covers the various pieces of software that make up Constabaris, developed
for the Long Civil Rights Movement project by UNC Libraries in collaboration with UNC Press.

The primary focus of the application is delivering scholarly works
(monographs, articles, and a limited set of other types of material)
as web pages while allowing users to add comments on specific
paragraphs.

The web pages are derived from TEI P5 sources meeting the requirements
developed by Ken Reed at UNC Press.  The web-based front end consists
of a `Django <http://www.djangoproject.com>`_ project and two custom
Django applications; the content may be prepared by supplementary
backend Java web application that uses XProc and XSLT to transform TEI
documents into 'ingest packages' which can be fed into the front-end.

The application as delivered allows for user self-registration and
access control, and seeks to provide a reasonably flexible while still
simple set of facilities for managing metadata.

Contents:

.. toctree::
   :maxdepth: 2

   architecture
   project
   apps/notes
   apps/works
   metadata
   apps/ingest
   apps/searching
   javascript
   packager




Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`





