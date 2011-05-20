from django import forms
from datetime import datetime
import models
import django.contrib.auth.models as authmodels
from tinymce.widgets import TinyMCE
from urllib import urlencode


# Provides a standardized way to render objects in forms
# where what's appropriate as a __unicode__ method might not
# be suitable 

class LabelChoiceField(forms.ModelChoiceField):
    """ModelChoiceField subclass that renders each model object's
    'label' attribute as the value."""
    def label_from_instance(self,obj):
        return obj.label

class ChoiceWithFreeFormWidget(forms.MultiWidget):
    """
    Renders input for a field whose value may come from a 'suggested'
    list of choices, or may allow free text entry.
    """
    def __init__(self,attrs={},choices=()):
        widgets = (forms.Select(attrs,choices=choices),
               forms.TextInput(attrs))
        self.choices = choices
        self.attrs = attrs

TINYMCE_CONFIG = {
        "plugins" : "paste,searchreplace,inlinepopups",
        "mode" : "exact",
        "theme" : "advanced",
        "skin" : "o2k7",
        "content_css": "/medea/css/styles.css",
        "theme_advanced_buttons1" : "bold,italic,separator,bullist,numlist,separator,link,unlink,separator,replace,separator,pasteword,cleanup,separator",
        "paste_auto_cleanup_on_paste" : "true",
        "theme_advanced_buttons2" : "",
        "theme_advanced_buttons3" : "",
        "theme_advanced_resizing" : True,
        "insertlink_callback" : "insertLink",
        "theme_advanced_disable" : "underline,strikethrough,justifyleft,justifyright,justifycenter,justifyfull,outdent,indent,image,code,hr,fontselect,fontsizeselect,formatselect,styleselect,cleanup,sub,sup,forecolor,backcolor,visualaid,anchor,newdocument,undo,redo",
        "theme_advanced_toolbar_location" : "top",
        "init_instance_callback" : "setTabIndex"
}


class UserForm(forms.ModelForm):
    """
    A form used to give users a way to update their own data.
    """
    class Meta:
        model = authmodels.User
        exclude = ('username', 'password', 'is_staff', 'is_superuser', 'groups', 'is_active', 'last_login', 'date_joined', 'user_permissions',)


class UserAccountForm(forms.ModelForm):

    about = forms.CharField(required=False,widget=forms.Textarea(attrs={ "rows" :5, "cols": 40, "maxlength":250 }),max_length=250)

    class Meta:
        model = models.UserAccount
        exclude = ('user','prior_approval', 'verified',)


class UploadForm(forms.Form):
    license = forms.ModelChoiceField(required=True,queryset=models.License.objects.all(), initial= models.License.objects.get(name="All Rights Reserved"))
    file = forms.FileField(required=True,help_text="A .zip file containing an ingest package or TEI file + images")

class IngestCommitForm(forms.Form):
    """
    Form to be displayed along with information about how the ingest package will be determined
    """
    upload_key = forms.CharField(widget=forms.HiddenInput())
    
class UpdateWorkForm(forms.Form):
    work = LabelChoiceField(required=True,queryset=models.Work.objects.all(),help_text="The work to be updated")
    cover = forms.FileField(required=False, help_text="An image file containing the cover art")
    package = forms.FileField(required=False,help_text="An ingest or pre-ingest package")
    
    
class AdvancedSearchForm(forms.Form):
    title = forms.CharField(required=False)
    subject = LabelChoiceField(queryset=models.Subject.objects.all(),required=False)
    keywords = forms.CharField(required=False)
    author = forms.CharField(required=False)
    genre = LabelChoiceField(queryset=models.Genre.objects.filter(enabled=True),required=False)
    open_access = forms.ChoiceField(required=False, initial='----', choices=(('----', None,), ('Open', True,), ('Closed', False,)))
    publishedYear = forms.IntegerField(min_value=1600, max_value=datetime.now().year+2,required=False)
    description = forms.CharField(required=False)
    
    def build_query_string(self):
        if not hasattr(self, 'cleaned_data'):
            self.is_valid()
        cd = self.cleaned_data
        p = {}
        if cd['title']:
            p['title'] = cd['title']
        if cd['subject'] is not None:
            p['lcsh'] = cd['subject'].label
        if cd['genre'] is not None:
            p['genre'] = cd['genre'].label
        if cd['author']:
            p['author'] = cd['author']
        
        params = {'qt' : 'standard'}
        # 'p' for 'parameter'
        pgenre = cd.get('genre', None)
        if pgenre:
            params['fq'] = 'genre: %s' % pgenre
        qstr = ""
        
        oa = cd['open_access']
        if oa not in (True,False):
            del cd['open_access']
        
        for k,v in cd.items():
            if k != 'genre' and v is not None and len( str(v).strip() ) != 0:
                key = k != 'subject' and k or 'lcsh'
                qstr += "%s: '%s'" % (key,v)
                #p[key] = v
        params['q'] = qstr
        self.params = p
        
        return urlencode(params, True)
