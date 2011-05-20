.. toctree:

Searching
**********

Search is implemented by `Haystack <http://haystacksearch.org>`_,
which provides an abstract, Djangotic interface to a number of
different search engines (we use solr).  Due to documentation
difficulties, I ended up using a non-final '1.1' prerelease; it seems
stable enough, but it's probably not available in any repositories ...

Basic Haystack Setup
=====================

This is a very compressed version of what's in the haystack
documentation, so really you should check that out first.  However,
here's a quickstart:

Set the needed configuration in your project's ``settings`` module,
including adding haystack as an installed app and setting the
properties it needs to identify and use the search engine.  Add a file
``haystack_sites.py`` in the project directory, and unless you have
special needs, have that file do autodiscovery.  Autodiscovery will
search each installed application for a ``search_indexes`` module,
wherein the mappings from model objects to search engine are defined.

Configuring Search Indexes
---------------------------

"Search Index" is haystack-speak for a class that handles how a Django
model object is mapped into the search engine backend, as well as how
updates to model objects are handled.  In our case, since we're using
Solr which can handle a constant stream of updates, WorkIndex and
SectionIndex classes subclass Haystack's ``RealTimeSearchIndex``
class, which uses Django signals to send updates to the search engine
as changes are made to the model objects.

The details for this are *mostly* straightforward, and I refer you to
``works/search_indexes.py`` for the details, but some explanation is
in order.  Works have an 'available' flag, and so we need to insert
special code to make sure that a work that is marked as unavailable,
as well as all its sections, are removed from the index so they won't
come up on searches (mutatis mutandis for previously unavailable works
that become available).

The text of a Section is basically the text that can be extracted from
its associated XHTML, with one small caveat -- inline foot- and
end-note references are present in the XHTML at the point of
reference, but (a) they're hidden by default (only displayed when the
user mouses over the reference mark), and (b) arguably aren't really
supposed to be there.  It's a bit annoying to get a search result that
says a given section contains a reference to something, and not be
able to see it with a simple Ctrl-F in the browser.  To avoid such
annoyances, the XHTML-extraction routine does not index inline note
text.

Search Result Display
-----------------------

Although both Works and Sections are indexed as documents in the
search engine, Sections don't have much of their own metadata and it
doesn't really make sense to present a Section outside the context of
its Work.  The problem is that Solr and Haystack can't natively
understand this, so they might produce a search result that includes
Sections and Works intermingled.

For example suppose I search for the name of an author who is
referenced in many places.  The results might come back from Haystack
looking like this::

 work 1
 section 11 of work 2
 section 3 of work 4
 section 1 of work 2
 section 3 of work 1
 work 4
 section 2 of work 3

This creates a bit of a problem when it comes to presentation -- how
do you make that jumble make sense to the users?  Presenting a section
as an individual hit means that we're not able to give it the proper
context (how is the user to know which work the section comes from,
e.g.).  Each Section is indexed separately, and Solr does not handle
hierarchy neatly, and when you throw the Haystack abstraction on top
of all that, well ...

By default, Haystack integrates the search results with the ORM, in
that each result coming back through Haystack contains an ``object``
attribute that is a reference to the model object that the result
represents.  So we can use this to navigate, from a hit on a section,
to the work that section comes from (viz. ``result.object.work``).

With a large result set, the ORM integration could create a
performance issue (a lookup against the database is performed for each
search result on the page), so Haystack allows for turning this
behavior off.  Note that if the collection grows, this could become an
issue.

The solution we adopted to present results in a way that doesn't do
too much violence to user's presumed expectations is to take the works
as primary and present each page of results as a list of works with
the matching sections of each work as subordinate to the work, and
present the works in the order in which we encounter them (either
directly, as matches in their own right, or indirectly, by virtue of
being the parent work of a matching section).  So, for example, in the
above result list, the results would be presented like this::
 
 work 1
  # section 3 of work 1
 work 2
  # section 11 of work 2
  # section 1 of work 2
 work 4
  # section 3 of work 4
 work 3
  # section 2 of work 3

The result is unsatisfactory in that the search engine's ordering told
us that section 11 of work 2 is the second best 'hit', but that result
is actually fourth on the list of presented results.  Notice also that
works 2 and 3 are not 'hit's in their own right, but they are
presented as if they are.  Overall, though, this seems better than
presenting each result on its own and duplicating a work's metadata
multiple times on a page of results.  

Searching Comments
--------------------

The main reason comments (``notes.Annotation`` objects) are not
currently indexed is that I couldn't come up with a neat way of
integrating their results into this already fractured scheme.  Another
reason is that I tried to avoid having the works app assume the
presence of the notes app, and given that the search views are defined
in the works app, keeping them separate was going to require more
thought than I had time for.

The mechanics of adding comments to the search engine's index should
be straightforward, however, as all that is needed for this is to
create ``notes/search_indexes.py``; the indexes defined in the works
app are available as examples.

Searching in Works
-------------------

As a demonstration, superusers have access to an asynchronous "search
inside this work" widget available by opening up the admin tools
dialog (that only superusers see).  I anticipate that the majority of
the work needed to make this available to users involves figuring out
how to integrate the widget into the site design.

Advanced Search
----------------

An "advanced search" page has been stubbed out, but since no
specification was developed for this feature, it was not implemented
or linked from anywhere.  See ``works/urls.py`` and ``works/views.py``
for more about this.

One challenge here is determining how to present a widget for boolean
valued fields (e.g. either I want only those things marked as open
acces, or I want only those marked as restricted access, or maybe I
don't care).  However, the Haystack API is pretty powerful (it allows
for chaining query parameters), and so this shouldn't be too hard to
implement once the UI aspects are worked out.

Search Index Management Commands
---------------------------------

Haystack provides a lot of useful management commands, and if you're
lazy/smart you can even just define all of your search indexes and run
one of these to create the Solr schema document.

Mostly, though, I just wanted to talk about ``./manage.py
rebuild_index``, which will *completely* reindex all of the model
objects.  Unless something odd happens, this shouldn't be needed, but
with 34 works, 8 papers, and 2 CCR documents a complete reindex takes
about a minute.

For more on Haystack management commands, see `the Haystack
documentation
<http://docs.haystacksearch.org/dev/management_commands.html>`_.









