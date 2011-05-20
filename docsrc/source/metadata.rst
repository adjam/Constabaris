=========
Metadata
=========

Metadata handling happens on two ends; first, when ingest packages are
created, one of the transformations that takes place takes the source
TEI document and generates MODS.  The resulting MODS is embedded in a
METS document which acts as the manifest for the ingest package.  The
*ingest* process involves extracting data from the resulting METS (and
other generated files), creating Django model objects, and setting
their attributes appropriately.

The ``mods:mods`` element is embedded as the content of ``mets:dmdSec`` in
the METS document.  Most of the metadata for a works.Work object is
extracted from this 'header', and it's also processed into other
objects (e.g. works.NamedPerson, works.WorkAuthoring, etc.).  The bulk
of the logic for extracting the XML into (intermediary) python objects
lives in the ``cdla.xmlmodels.mets.METSDocument`` class.  

A sample MODS 'header':

.. literalinclude:: mods-example.xml
   :language: xml

Suppose we instantiate a ``cdla.xmlmodels.mets.METSDocument`` object
in python code, and give it the name ``mets``. At this point the MODS
section has been processed and forms the basis of the the new object's
``metadata`` attribute -- a custom ``dict``-like object (see
the ``AttrDict`` definition in the mets.py file) containing various types
of objects.

Certain mappings are straightforward:

-----
Title
-----
``/mods:mods/mods:titleInfo/mods:title``
 (sim. for subtitle)
 =>  This becomes the value of ``mets.metadata['title']``

----- 
Genre
----- 
``mods:genre`` 

The text value of this element will ultimately be matched against
the ``name`` attribute of of a ``works.Genre`` element that is already
stored in the database (Genre objects are loaded via the Django
*fixture* mechanism, and are encoded into the
``fixtures/initial_data.json`` file in the ``works`` application
directory.  If the genre is somehow not encoded in the MODS, a default
of 'Book' is selected.

Genre "name"s typically follow the `Eprints Type Vocabulary Encoding Scheme
<http://www.ukoln.ac.uk/repositories/digirep/index/Eprints_Type_Vocabulary_Encoding_Scheme>`_
where possible, with the exception of "Manual" which is not usually a
scholarly work; genre objects also have URIs and descriptions, and carry a
custom field "citation_type" that is used to determine how to format citations.
At present, little use is made of the fact that genres have URIs.

Note that the fixtures shipped currently set the `enabled` attribute to `False` for most of the genres, to indicate that they're not in use.

------------------------------------
Library of Congress Subject Headings
------------------------------------
``mods:subject[@authority='lcsh']/mods:topic`` 

These are ultimately managed as Django model objects (``work.Subject``), and
here are stored as a list of strings at ``mets.metadata.subjects``

-------------------
Authors and Editors
-------------------

``mods:name[@type='personal']`` 

These are ultimately mapped to Django ``NamedPerson`` objects via
``WorkAuthoring`` objects -- the latter represents the relationship
between and author or editor and a work.  The ``NamedPerson`` object
contains multiple types of name (basically, a registered form and a
display form), and may be further linked to a Django User object so
that authors registered in the system can be related to their Works.
The relationship between ``NamedPerson`` and ``User`` objects must be
managed through the Django admin, since it is difficult to encode
(ephemeral, unrelated) user information into the TEI.  The
author/named person/authoring relationship is processed into a
(non-model) ``Author`` object in the ``cdla.xmlmodels.mets`` file.

-----------
Identifiers
-----------
``mods:identifier[@type='isbn']`` and ``mods:identifier[@type='doi']``

-------------------- 
Description/Abstract
--------------------
``mods:abstract`` 

This is misleading; this value is put into the metadata dict, but it's
not used at the point of ingest.  The reason is that it's possible to
use a slightly richer syntax in the
``teiHeader/tei:note[@type='abstract']`` element directly from the TEI
document, so as to allow some formatting and link embedding.

============================
Metadata Extracted from TEI
============================

Most of the metadata is encoded as MODS and extracted from METS, but
in some cases we need to go straight to the TEI source, usually where
the metadata is non-standard or needs to be treated as HTML.  To aid
in this process, the class ``cdla.xmlmodels.tei.TEIDocument`` is used,
in parallel to the ``METSDocument`` class outlined above.

---------
Keywords
---------

``//tei:keywords[@scheme="urn:keywords"]/tei:list/tei:item``

These are simple text values (derived from 'keywords' cooked up by
marketing staff at UNC Press), and end up as ``Tag`` objects from the
``django-tagging`` reusable app.  A common gotcha is that tags may
only be fifty characters long, and that the mechanism used to create
them also has a built-in size limit (400+ characters for all tags).
Violating these strictures has a tendency to produce duplicate key
errors when it comes to inserting values in the database.

---------
Abstract
---------
``tei:note[@type='abstract']``

These aren't abstracts in the strictest sense, often they're taken
from UNC Press marketing copy; at any rate, they may have some
formatting and may contain embedded links, and so a small XSLT
stylesheet ``abstract2html.xsl`` is used to turn the contents of the
above element into an HTML fragment.  The XSLT file is embedded
alongside the python files in the ``cdla.xmlmodels`` module.

TODO: investigate possiblity of embedding HTML abstracts directly into
MODS?  Would involve moving ``abstract2html.xsl`` into packager app, where
it arguably belongs ...

------------
ExternalURLs
------------
``tei:ref[@type='uriref' or @type='doi']`` in teiHeader

These allow linking to OCLC or UNC Press pages, and end up as managed
Django model objects.




