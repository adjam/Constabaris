Javascript / jQuery Stuff
**************************

Most of the whiz-bang stuff the site does is done through `jQuery
<http://jquery.com>`_, wiht an assist from `jQuery UI
<http://ui.jquery.com>`_.  Where possible, local functions are bundled
up as properish jQuery plugins, which are kept in the
:file:`{{MEDIA_ROOT}}js/plugins` directory.  This document should
serve as an overview to let you know where to get started.

jQuery Real Quick-Like
=======================

The basic model for jQuery usage is that you import all of your
libraries using ``<script>`` tags, and then embed some code that
initializes everything once the browser has finished loading the DOM.
jQuery relies heavily on two principles:

 # locating nodes with CSS selectors (with some custom extensions)
 # using functional programming to add the fancy behavior

.. code-block:: javascript

 <script type="text/javascript">
   $(document).ready( 
       function() {
           $("#comments").hide();
       }
   );
 </script>

What the above does is tell jQuery to install a 'document ready'
handler, an (anonymous) function that locates the element in
the page that has the id ``comments``, and invokes the ``hide()``
plugin on it (this is a jQuery stock plugin that sets the CSS
``display`` property of the element to ``none``).  By using third
party plugins and writing your own, you can add quite a bit of
functionality to a web page.

jQuery UI
----------

jQuery UI is a companion to jQuery, it encompasses a bunch of
'standard' rich-UI widgets (date pickers, modal dialogs, etc.) backed
by jQuery.  The primary use on this site is to set up the inline
commenting feature.

Custom Plugins
===============

:file:`js/plugins/comments.js`
-------------------------------

The primary use for this plugin is to enrich the individual sections
of a work; it adds clickable pilcrow marks to paragraphs, hover
styles, and of course the comment bubbles and the commenting feature.

One of the primary considerations in the design of the commenting
feature is that it should, as far as possible, be usable without
javascript; so it works via progressive enhancement, turning the basic
form into an AJAXish one, and adding the paragraph-level comment
bubbles after the page is loaded.

The code, as convoluted as it is, must largely speak for itself. To
the extent it's been worked over since the initial proof of concept,
that was to enhance programmer readability (no, really) without paying
too much attention to execution speed.

In a nutshell, here's what the workhorse `commentify` plugin does:

* Hides ``div#comments`` and turns it into a dialog 
* locates all of the commentables (~ <p> tags with IDs) 
* for each commentable: 

  * create an ``.annotation-hook`` marker for it
  * place the marker inside the paragraph
  * count the comments pointed at the commentable, and put that number
    into the annotation hook.  
  * add a 'click' handler for the marker that 

    * populates the comment form's hidden input indicating the commentables' ID
    * prepare the tabs in the comment dialog
    * shows the comment dialog.

* add jQuery UI `tabs` to the comment dialog, one for 'all comments'
  on the current page, one for 'comments on the current paragraph',
  and one for some help with the commenting system.

It really helps to understand jQuery and jQuery UI when tackling all
of this, so don't touch it until you have a sense of how to read that
kind of stuff.  And I apologize in advance for the convolutions.

:file:`{{MEDIA_ROOT}}/js/plugins/moderation.js`
-----------------------------------------------

Adds functions for moderators, allowing users with sufficient
privileges to approve or delete comments.

:file:`{{MEDIA_ROOT}}js/plugins/search.js`
-------------------------------------------

This is where the javascript for the administrator-only AJAXy 'search
in this work' function lives.  Because I had nowhere else to put it,
also contains an AJAXy thing designed to help content uploaders locate
the correct work when updating content (see
``templates/works/ingest/update.html``)

Third-Party jQuery Plugins
===========================

:file:`{{{MEDIA_ROOT}}}/js/plugins/jquery.hoverintent.js`
---------------------------------------------------------

This adds the `hoverIntent` plugin, which adds a bit of logic for smoother
detection of 'hover' events (instead of basically firing on mouse over/mouse
out, it tries to detect whether the user appears to want to linger over the
element).


:file:`{{{MEDIA_ROOT}}}/js/plugins/jquery.jgrowl.js`
____________________________________________________

This adds `jGrowl <http://stanlemon.net/24>`_, a plugin that shows relatively
unobtrusive yet noticeable notifications.  Right now the only use for this is
to provide feedback to users that have submitted comments. 






