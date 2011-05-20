# Create your views here.

import pprint

from django.http import HttpResponse, HttpResponseNotAllowed,HttpResponseForbidden
from django.views.decorators.http import require_POST
from django.shortcuts import get_object_or_404, redirect, render_to_response

from django.template import RequestContext, Context
import django.template.loader as tmpl_loader
from django.contrib.auth.decorators import login_required, permission_required

from django.contrib import comments
from django.contrib.comments import signals
from django.db import models as dm

from django.utils.html import escape as html_escape
from models import Annotation,Format
from works.models import Work 

from forms import AnnotationForm

from django.core import serializers

import simplejson as json

import logging

from conf import settings

log = logging.getLogger("notes.views")

@login_required
def create(request, next=None, template="comment-received.html"):
    try:
        comment = _handle_post(request)
    except CommentPostError, ce:
        return comments.views.comments.CommentPostBadRequest(ce)
    if request.is_ajax():
        try:
            json_content =  _serialize_annotation(comment)
            return HttpResponse(json_content,mimetype="application/json")
        except Exception, x:
            log.error("Unable to save comment for user [%s]: %r" % ( request.user, x) )
            return HttpReponseServerError("Unable to save comment: %r" % x)
    else:
        log.debug('notes.views.create - std HTTP')
        ctx = RequestContext(request,{ 'next' : next })
        target = getattr(comment, 'content_object', None)
        ctx['target'] = target
        return render_to_response(template, ctx)
    
    

def _handle_update(request,note):
    if not note.can_edit(request.user):
        return HttpResponseForbidden()
    form = AnnotationForm(request.POST)
    if form.is_valid():
        note.comment = form.cleaned_data['comment']
        note.save()
        return HttpResponse(_serialize_annotation(note), mimetype="application/json")
    else:
        return HttpReponse(unicode(form.errors))
    
    

def by_id(request,id=0):
    note = get_object_or_404(Annotation,pk=id)
    if request.method == 'GET':
        return _handle_get(request,note)
    if request.method == 'DELETE':
        return _handle_delete(request,note)
    if request.method == 'POST':
        if request.POST.get("action", "update") == "DELETE":
            return _handle_delete(request,note)
        return _handle_update(request,note)
    else:
        return HttpResponseNotAllowed()
        
by_id = permission_required('notes.can_moderate')(by_id)

def _serialize_annotation(note):
    rv = {}
    comm = comments.models.Comment.objects.get(pk=note.pk)
    rv['id'] = comm.pk
    rv['user_pk'] = comm.user.pk
    rv['approved'] = comm.is_public
    rv['content'] = comm.comment
    rv['target'] = note.content_internal_path
    tmpl = tmpl_loader.get_template("comment.html")
    rendered = tmpl.render( Context({'comment' : note, 'authors' : []}) )
    rv['rendered'] = rendered
    return json.dumps(rv)
    
    
def _handle_get(request,note):
    comment = get_object_or_404(comments.models.Comment,pk=note.id)
    user = request.user
    if note.is_public or user.has_perms('notes.can_moderate'):
        return HttpResponse( _serialize_annotation(note))
        #serializers.serialize("xml", [note, comment]) )
    
def _handle_delete(request,note):
    pk = note.pk
    note.delete()
    return HttpResponse("Note %d has been removed" % pk)

@require_POST    
def approve(request,id=0):
    note = get_object_or_404(Annotation,pk=id)
    note.approve()
    return HttpResponse("Annotation %d was approved" % ( note.id ))

approve = permission_required('notes.can_moderate')(approve)
    
def show_form(request):
    console.log('notes.views.show_form - request:')
    console.log(request)
    fmt = Format.objects.get(pk=1)
    # wrk = Annotation.objects.get(pk=)
    form = AnnotationForm(fmt)
    ctx = RequestContext(request,{'form' : form})
    return HttpResponse(form.as_table())

def list(request):
    
    if request.user.has_perm("notes.can_moderate") or request.user.is_staff:
        qs = Annotation.objects.order_by("-submit_date")[:25]
    else:
        qs = Annotation.objects.filter(approved=True).order_by("-submit_date")[:25]
    return HttpResponse(unicode(qs))
    


class CommentPostError(Exception):
    pass


# the below is lifted straight from django.contrib.comments.views.comments.py
# it comes from the post_comment method, but has been modified to only handle
# comment submission and returns the newly created comment,
# leaving delegation of the repsonse to the calling method.

def _handle_post(request, next=None):
    """
    Post a comment.

    HTTP POST is required. If ``POST['submit'] == "preview"`` or if there are
    errors a preview template, ``comments/preview.html``, will be rendered.
    """
    # Fill out some initial data fields from an authenticated user, if present
    data = request.POST.copy()
    if request.user.is_authenticated():
        if not data.get('name', ''):
            data["name"] = request.user.get_full_name()[:50] or request.user.username
        if not data.get('email', ''):
            data["email"] = request.user.email

    # Check to see if the POST data overrides the view's next argument.
    next = data.get("next", next)

    # Look up the object we're trying to comment about
    ctype = data.get("content_type")
    object_pk = data.get("object_pk")
    work_id = data.get('work_id')
    if ctype is None:
        raise CommentPostError("Missing content_type.")
    if object_pk is None:
        raise CommentPostError("Missing object_pk")
    if work_id is None or work_id is 0:
        raise CommentPostError("Missing work_id")
    try:
        model = dm.get_model(*ctype.split(".", 1))
        target = model._default_manager.get(pk=object_pk)
    except TypeError:
            raise CommentPostError("Invalid content_type value: %r" % escape(ctype))
    except AttributeError:
        raise CommentPostError("The given content-type %r does not resolve to a valid model." % escape(ctype))
    except ObjectDoesNotExist:
        raise CommentPostError(
            "No object matching content-type %r and object PK %r exists." % \
                (escape(ctype), escape(object_pk)))

    # Do we want to preview the comment?
    preview = "preview" in data

    # Construct the comment form
    form = comments.get_form()(target, data=data)

    # Check security information
    if form.security_errors():
        raise CommentPostError("The form has apparently been tampered with: %s" % escape(str(form.security_errors())))

    # If there are errors or if we requested a preview show the comment
    if form.errors or preview:
        return form

    # Otherwise create the comment
    comment = form.get_comment_object()
    comment.ip_address = request.META.get("REMOTE_ADDR", None)
    if request.user.is_authenticated():
        comment.user = request.user

    # Signal that the comment is about to be saved
    responses = signals.comment_will_be_posted.send(
        sender  = comment.__class__,
        comment = comment,
        request = request
    )

    for (receiver, response) in responses:
        if response == False:
            raise CommentPostError( "comment_will_be_posted receiver %r killed the comment" % receiver.__name__)

    # Save the comment and signal that it was saved
    comment.save()
    signals.comment_was_posted.send(
        sender  = comment.__class__,
        comment = comment,
        request = request
    )
    return comment