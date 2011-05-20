**************
The Notes App
**************

This application is a very light set of customizations on the
'standard' ``django.contrib.comments`` app, using (mostly) standard
extension mechanisms.  For more about the comments app and how to
extend it, see `Django’s comments framework
<http://docs.djangoproject.com/en/dev/ref/contrib/comments/>`_

The main two functional differences between the ``notes.Annotation``
object and the stock ``comments.Comment`` object are the addition of
the ``content_internal_path`` attribute, and the 'can_moderate'
permission.

The former adds a pointer to (in the present case) the XHTML ID of the
element being annotated, although no specific restrictions are placed
on the format of this attribute; it could thus be used to denote an
area on a photograph (by, say, describing a polygon).  It is up to
other applications to "understand" this attribute.

The custom permission is used to enable *in situ* moderation of
comments.

The base functionality of the 'standard' comment app uses Django's
content types ("generic foreign key") framework to relate comments to
*any* Django model object.

=====================
Other Customizations
=====================

The ``forms.py`` in this app contains some custom logic to handle
submission of comment bodies that contain user-submitted HTML.  It
uses ``lxml.html``'s `Cleaner
<http://codespeak.net/lxml/lxmlhtml.html#cleaning-up-html>`_ framework
to strip javascript, restrict the range of allowed elements, and add
``rel='nofollow'`` attributes to embedded links.

``views.py`` contains some custom logic to *only* allow posting of new
comments by logged in and registered users of the system, and to allow
for some moderation and asynchronous POSTing of new comments.

-------------
Template Tags
-------------

In order to support moderation (by appropriately privileged users)
it's necessary to show *unapproved* (``is_public == False``) comments
to moderators, so we overrode the stock template tag to allow this.

----------
Templates
----------

It's probably worth mentioning that the specialized commenting form's
template is defined under `templates/form.html` in this app.
