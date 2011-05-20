from models import Annotation
from forms import AnnotationForm

from django.core.urlresolvers import reverse

import views

def get_model():
	return Annotation

def get_form():
	return AnnotationForm

def get_form_target():
	return reverse('note.create')
