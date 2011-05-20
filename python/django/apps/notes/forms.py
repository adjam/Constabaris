from django import forms
from lxml.html import clean
from lxml import etree
from tinymce.widgets import TinyMCE
from models import Annotation,Format
from django.contrib.comments.forms import CommentForm
from tagging.forms import TagField

class AnnotationForm(CommentForm):
    """
    CommentForm subclass that adds extra pieces for
    fields that exist on the Annotation object, including filtering
    of HTML inputs.
    """
    class Media:
        js =  ('js/tiny_mce/tiny_mce.js',) #'js/plugins/comment_validate.js',)

    genre = forms.CharField(max_length=128,
                            required=False,
                            widget=forms.HiddenInput())
    format_id = forms.IntegerField(
                              widget=forms.HiddenInput(),
                              required=False,
                              initial=1)

    work_id = forms.IntegerField(widget=forms.HiddenInput(),
                                required=False)
                                
    # uncomment the following to enable adding tags
    #tags = TagField()
    
    content_internal_path = forms.CharField(max_length=512,
                                           widget=forms.HiddenInput,
                                           required=False)

    def custom_visible_fields(self):
        """
        Gets the fields that should be visible to regular users of the form.
        """
        flds = [ x for x in self.visible_fields() if x.name in ('honeypot','tags', 'comment') ]
        flds.sort(lambda x,y: cmp(x.name,y.name))
        flds.reverse()
        return flds

    def get_comment_model(self):
        return Annotation
    
    def clean_comment(self):
        """
        Attempts to sanitize HTML content
        """
        raw = self.cleaned_data.get('comment','')
        if len(raw.strip()) == 0:
            raise forms.ValidationError("Comment is blank")
        cleaner = clean.Cleaner(safe_attrs_only=True,add_nofollow=True,remove_tags=['body','head','hr','h1','h2','h3','h4','h5','h6','img'])
        cleaned = " ".join( cleaner.clean_html(raw).split() )
        return cleaned
    
    def get_comment_create_data(self):
        data = super(AnnotationForm,self).get_comment_create_data()
        data['content_internal_path'] = self.cleaned_data['content_internal_path']
        data['format_id'] = self.cleaned_data['format_id']
        data['genre'] = self.cleaned_data['genre']
        data['work_id'] = self.cleaned_data['work_id']
        return data    

