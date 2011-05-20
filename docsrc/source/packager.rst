****************
TEI Packager App
****************

This is a web application, written in Java and using only basic
servlets as the view technology.  It essentially provides an
HTTP-accessible wrapper around an `XProc <http://xproc.org/>`_
pipeline; the pipeline transforms incoming TEI P5 XML and produces
METS, one or more XHTML files, which it then bundles up with the TEI
into a "Full Ingest Package," which is what the ingest process in the
:doc:`apps/works` reads into the database.

It is, unfortunately, quite a bit more complicated than it really
needs to be, however it gets the job done.  

Licensing
===========

A non-technical issue with this application is that there is an
"Intellectual Property" agreement between the principal investigators
and the Mellon Foundation stipulating that the software developed for
the project must be releasable under the `Educational Community
License v 2.0 <http://www.opensource.org/licenses/ecl2.php>`_, a
variant on the Apache License v 2.0.  However, the XProc
implementation used in this application is `XML Calabash
<http://xmlcalabash.com/>`_, which is released under the GPL v.2
(according to its website); this means, arguably, that the packager
application must also be released (if it is released) under the terms
of the GPL v.2 (see, for example
http://www.gnu.org/licenses/lgpl-java.html).

Other XProc implementations exist, however none of which the author is
currently aware are available as replacements; Calumet, developed by
the EMC corporation, is only available as part of an expensive
software suite and inquiries about licensing just Calumet did not get
very far.  The `eXist XML Database <http://www.exist-db.org>`_ bundles
an XProc implementation as of version 1.4, however given our local
difficulties with running eXist stably and the different application
development model, integration with eXist was not pursued.

Resolution of this issue is left as an exercise for the PIs; there
are, broadly speaking, two forms -- one of which is to exclude the
packager app from what's included in the "Project Software", and
another is to establish definitively that the GPL'd nature of this
portion of it is not a violation of the IP agreement.

Usage
=============

Interactive Mode
-----------------

ZIPs containing TEI and embedded images or lone TEI P5 files may be
uploaded to the (HTML5!) form at the webapp's main page.  The servlets
will then extract (if needed) the TEI, generate METS and XHTML files,
and then produce a ZIP file.  The results page for this "interactive"
use then offers the option of downloading the newly created package or
continuing to upload packages.  The packages uploaded during a session
(which 'ends' if the session cookie is deleted or the browser closed,
or when the server times out the session after 30 minutes of
inactivity) are always available by clicking on the 'session' link at
the head of the page.

Service Mode
--------------

Alternately, a "service mode" is available at ``[context
root]/service/``; this 'endpoint' accepts POSTed zips and TEI files
(based on the value of the ``Content-Type`` header), and immediately
returns the resulting full ingest package as the value of the response
body.

Sample usage of service mode from :command:`curl`::

 $ curl -X POST -H"Content-Type: application/zip" --data-binary \
 @tei.zip -o ingest.zip http://localhost:8080/tei-package/service/

or::

 $ curl -X POST -H"Content-Type: application/tei+xml" --data-binary \
 @tei.xml -o ingest.zip http://localhost:8080/tei-package/service/

An example from usage within python can be found in :file:`utils.py`
in the works app directory.

Application Source + Building
==============================

The application is built by `Apache Maven <http://maven.apache.org>`_,
and its source code organization conforms to basic Maven patterns:

* :file:`src/main/webapp` - Web application files, ``WEB-INF`` directory, JSP
  files, etc.  

* :file:`src/main/java` - main application code 

* :file:`src/test/java` - Java unit test cases 

* :file:`src/main/resources` - the "resource directory, which contains
  other files that should end up on the application's classpath.

This last is important is because that's where the files you are most
likely to need to modify are stored: :file:`xpl/ingest.xpl` is the
'driver' for the ingest process -- it provides the basic structure of
the XML-related operations that are performed.

:file:`xpl/uncp-cleanup.xpl` in the same directory is a library of
functions that are used by the driver pipeline; these functions are
unfortunately Calabash-specific, although some attempt has been made
to universalize them so they could be made to work with any XProc
implementation.

Finally, the :file:`xsl` subdirectory in the resource directory is
where the XSLTs that generate XHTML from TEI are stored.
:file:`xsl/driver.xsl` is the 'master' stylesheet and can be run
directly by any XSLT 2.0 processor, which means, in effect, Saxon 9.
It's been tested against both Saxon 9.1.x and Saxon 9.2.x, but with
the latter, *not in production*.  The packaging and licensing of Saxon
9 changed between these two versions.

A brief overview of building with maven and how that works is
available on the Library Systems Wiki at
https://jack.lib.unc.edu/wikis/systems/index.php/JavaWebapp#tei-package

Another maven target worth mentioning is one that can be used to build
the project and run it in a local Jetty instance with :command:`mvn
jetty:run` -- this will build the service and start the application
container at ``http://localhost:8080/`` (note: no `tei-package` here
at the end of the URL).  This allows for application testing.  Note
that the application container will reload if any of the Java source
or resource files are touched -- this is mostly convenient, although
it will tend to result in the server process running out of memory
after a few reloads; hit Ctrl-C and rerun the ``jetty:run`` target if
this happens.


Application Design
======================

For Java developers familiar with how basic servlet applications work,
the only strikingly new portion of the application are the portions
that wrap Calabash.  Very very roughly, the idea here is that a
Calabash process -- the execution of a `pipeline` -- has a number of
`input` ports and a number of `output` ports.  A `port` is an abstract
kind of thing that either accepts or emits one or more XML documents.

Which ports are present and what type of XML is expected or produced
on any given port depends on the pipeline being processed.  A pipeline
is essentially a series of `steps`, where the output(s) of some steps
are directed to the input(s) of other steps, so as to produce one or
more results.  XProc steps can run XSLTs, as they mostly do here, but
they can also send documents over HTTP, perform zip/unzip operations,
etc.  Given time constraints and limited scope, I was unable to
explore these other features.

XML Calabash uses Saxon 9 to provide the basic XML handling, and as a
result the object type that arrives at a port (incoming or outbound)
will implement the Saxon 9 API ``XdmNode`` interface.  This is a very
abstract and general sort of beast (documents, elements, etc. all
implement it), and is actually somewhat removed from such mundane
concerns as filesystem locations.  

A good hunk of the code in the application outside of the servlet
stuff is there to help process ``XdmNode`` objects.  You are hereby
referred to http://www.saxonica.com/documentation/javadoc/index.html
for more details, although note that that URL documents the latest
version of Saxon (9.2 at the time of this writing), not the version
9.1.0.8 we are using locally.

In both modes, ingest is handled by the `PipelineServlet`, which
determines what was uploaded, unpacks it, if necessary and writes the
uploaded files to a temporary directory.

The 'detected' TEI file (preferably the file named ``tei.xml`` in the
zip, failing that the first file with an ``.xml`` extension is used)
is then sent to the *primary input port* of the pipeline, whereupon it
is 'cleaned up' (although most of the cleanup is no longer
necessary;long IDs are truncated, paragraph IDs are added if
necessary, etc.) -- the 'cleaned up' document is then sent through the
rest of the pipeline as the source to be transformed.

METS is generated by running the :file:`tei2mets.xsl` XSLT -- the
resulting document is on what's known as the primary output port for
the main pipeline.  The pipeline also calls :file:`driver.xsl` to
generate the (one or more) XHTML fragments.  This stylesheet has, as
its primary output, a project-specific map of IDs and targets within
the TEI document, which is used by the stylesheet to make sure all of
the internal links resolve correctly.  Once the transformation to
XHTML is complete, however, this document is not needed and so the
pipeline simply discards it.  The XHTML documents are output on the
pipeline's 'secondary' port.  The 'cleaned up' TEI is also sent to
another custom output port.

Custom classes that wrap the pipeline execution handle all of the
outputs and serialize them to a temp directory.  If a zip was input,
any image files in that zip are copied over to the temp directory, and
then that entire directory is zipped up into the ingest package.  

At this point, control is passed back to the `PipelineServlet`, which
either creates an entry for the upload in the current session
(interactive mode) or sends the generated ingest package back as the
response body.

Updating XSLTs
===============

Since the components of this process that is most likely to change are
the XSLTs used to generate the XHTML, I worked out a facility that
allows the application to store those XSLTs on the filesystem
somewhere.  If the directory specified (see the context parameters
specified in :file:`WEB-INF/web.xml` in the webapp source directory)
does not exist, then the versions of the pipeline documents on the
classpath will be used.  This allows the XSLTs to be updated without
reloading or redeploying the webapp.

See the documentation in the systems wiki (referenced above) for more
details.

Other Notes
============

The application works pretty hard to get rid of temp files once
they're no longer needed; they're typically created under the temp
directory created by the servlet container for the webapp (see the
wiki page for Tomcat location).  However, stuff happens and so you may
need to hit ``[context root]/cleanup/`` occasionally, which basically
blows away all of the temp files.  You'll need to pass a parameter
``authz`` with a specific value in order to access this function, see
the source code for `CleanupServlet` for details.

This shouldn't be an issue unless the disk space is filling up,
however.













