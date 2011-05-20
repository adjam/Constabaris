# Create your views here.

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
from django.core import serializers

import simplejson as json

import MySQLdb

import logging

from conf import settings

log = logging.getLogger("notes.updates")


def update_annotation():
    log.debug('udpate_annotation . . .')

    from models import Annotation
    
    annotations = Annotation.objects.all()

    from works.models import Work, Section        

    try:
        for a in annotations:        
            try:
                a.work = Section.objects.get(id=a.object_pk).work
                a.save()
                log.info('Updated '+str(a.id)+' with work id, '+str(a.work.id))
            except:
                log.info("couldn't find a section for "+str(a.object_pk))                
        log.info('Annotations updated with relationship to work')
    except MySQLdb.OperationalError:
        log.error('It looks like you have not added a work_id column to your notes_annotations column. Try this:\n ALTER TABLE notes_annotation ADD COLUMN work_id INT;\n and try again')
            