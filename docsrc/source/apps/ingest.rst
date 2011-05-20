The Ingest Process
*******************

Ingest is typically achieved by navigating to `[site
root]/works/ingest/` and uploading a ``.zip`` file that has a certain
structure. Access to ingest views are restricted to superusers, both
because of the importance of the process and the level of knowledge
required to create even a basic ingest package.

What happens next depends on what, exactly, was uploaded, but it
usually involves tearing apart a METS file along the lines described
in :doc:`../metadata` and turning it into various model objects from
the `works` app ...

Basic Ingest Packages
=====================

This is almost certainly how content gets into the system; a full
ingest package is somewhat more complex, but if the packaging
application should ever come down and be turned into something that a
desktop user runs before submitting to the site, might become more common.

At any rate, this is the expected file structure for a basic ingest
ZIP archive::

  uncp-[isbn].xml
  figures/
         fig01-[isbn].png
         ...
         fig17-[isbn].jpg

The package may contain other files, but they will typically not be
processed in any way by the packager.  The `tei-package` Java
servlet application is responsible for turning basic ingest packages
into full ingest packages.  The location of the packager app is
determined by the ``PACKAGER_SERVICE_URL`` setting in the `works`
project.

Note that the packager app searches first for a file named ``tei.xml``
in the archive, and if no such file is found it uses the first file
with a ``.xml`` extension as the TEI.  It then applies a sequence of
transformations to the TEI file to generate METS and XHTML fragments
for each of the sections, locates the referenced image files, and
repackages the results into a new ZIP archive, which is a full ingest
package.

Full Ingest Packages
=====================

A full ingest package is somewhat more regimented structure than the basic::

  mets.xml
  tei.xml
  content/
          001-segment.html
          ...
          012-segment.html
          figures/
                  fig01-[isbn].png
                  ..
                  fig17-[isbn].jpg

The numeric prefixes on the ``.html`` files denote the order of the
section they represent; for example, ``001-segment.html`` typically
represents the front matter of a book, while ``002-segment.html``
represents an introduction or chapter one.  

One of the 'services' provided by the packaging app is to ensure that
the intra-document links (from e.g. footnote references to notes) end
up pointing to the right file.  e.g. if the original TEI has something
like::

 <p>Miners were described variously as 
  "raucous"<ref type="noteref" target="#n2.2" n="2"/>, 
  "undisciplined"<ref type="noteref" target="#n2.3" n="3" />, 
   and "dirty"<ref type="noteref" target="#n2.4" n="4" /> 
 ...  
 </p>

And, further down (many sections away)::

 <note xml:id="n2.2">
  <num>2</num>
  <p>Jenkins, Thomas: Catastrophe in the Foothills, p. 17</p>
 </note>

The main body text containing the references might be in
``003-segment.html`` while the (endnotes) are in ``013-segment.html``,
meaning that for the link to the footnote to resolve in a browser, the
``href`` attribute of the anchor tag must be ``013-segment.html#n2.2``
(additionally, the notes point back to the point in the text from
which they are referenced, but the issue is essentially the same).

Ingest Type Detection
----------------------

The ingest process discriminates between basic and full ingest
packages by the presence (full) or absence (basic) of a
:file:`mets.xml` file in the archive.  If a basic package is detected,
the uploaded file's contents are sent to the packaging app for
processing; otherwise, the package is processed without further
modification.

Processing Full Ingest Packages
================================

Most of the ingest logic lives in the :file:`ingest.py` file in the
works app directory.  This is a somewhat complex beast comprising a
number of classes.

:mod:`works.ingest` -- Create model objects from ingest packages
-----------------------------------------------------------------

.. module:: ingest
   :synopsis: Functions for processing ingest packages.

.. moduleauthor:: Adam Constabaris <adamc@unc.edu> (ha!)

.. class:: IngestArchive(zip_path)
   
   A wrapper around a zip file that provides straightforward
   access to specific files in the archive

   .. method:: get_entries()

      Get the names of the entries in the archive

   .. method:: get_mets()
  
      Get a file-like object that reads the METS object in the archive

   .. method:: get_tei()

      Get a file-like object that reads the TEI file in the archive.
      

.. class:: IngestContext(archive_path)

   Provides higher-level abstractions over the contents of an IngestArchive.

   .. attribute:: mets

      An lxml.etree document representing the infoset of the METS file in
      the archive

   .. attribute:: tei

      An lxml.etree document representing the infoset of the TEI file
      in the archive

   .. attribute:: segments
 
      The segments (old name for Sections) extracted from the
      ``mets:div`` elements taken from the METS file.

   .. attribute:: media

      The media (image) files extracted from ``mets::file`` elements
      in the METS file.

.. class:: IngestAction(context)

   An object that processes the IngestContext into model objects.

   .. method:: execute(work=None,commit=False)

      Creates all the model objects; if `work` is None, creates a new
      work object, otherwise the action will *update* existing works.
      If `commit` is True, will save the model objects and copy the
      relevant files to the works' content directory.

      Returns a dict containing the created objects (whether they have
      been saved to the database or not)

   







 * ``IngestContext`` - roughly, this contains the basic parameters for an
   ingest operation, in that it wraps the ingest package ZIP archive
   and provides functions to query and access the files contained
   within (e.g. METS, TEI, image files)

 * ``IngestArchive`` - lower level wrapper around ZIP used by ``IngestContext``

 * ``IngestAction`` - contains the logic for performing the ingest.

Note that the ingest-related views have been broken out into their own file
for ease of maintenance; :file:`ingest_views.py`` is imported by the
default ``views``.

However it comes by it, once a full ingest package is in hand, the
application proceeds to unpack it and create (but not save) Django
model objects, which are used to generate a confirmation screen.  The
confirmation screen is designed to show the major metadata on the
works, the sections that were generated, and thumbnails of the images
found in the archive.  If everything looks in order, the user clicks
`confirm` and, essentially, all of the objects generated for the
'confirm' screen are re-created and saved.

HTML Filtering
===============

Generally, images, METS, and TEI files are simply copied into the new
work's content directory, but the HTML files need further processing
-- since the packaging app knows naught of Django, or the work's
eventual URL, or even basic bodily hygeine, it generates simple static
URLs for all the intra-document references (to other sections and to
embedded media files).

As the section above indicates, the HTML that comes in will have all
sorts of intra-document links to *files* named ``001-segment.html``,
but those files are typically not served by the web server, for two reasons

 * they're just HTML fragments
 * we need to let Django check whether the user has access to the
   section in question.

What we did was make the need to place Django between the user and
sections work for us, and thus the ingest process turns the static
XHTML in the ingest package into Django templates (see also
:ref:`dynamic-ssi`); thus, a link to ``013-segment.html`` is turned
into a link to ``{% works:section
'miners-strikes-in-the-west-virginia' 13 %}`` -- when Django loads the
templatized section XHTML, it is able to properly resolve the link.
Note that the values needed for this templatification aren't available
until we have the work's slug and the section in hand.

Similar mechanisms are used to make sure ``img`` tags in the XHTML are
properly converted.  Finally, the filtering process strips out the
namespace declaration on the root element of the XHTML fragment, in
order to give us a fighting chance at producing valid XHTML.











