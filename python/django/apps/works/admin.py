from django.contrib import admin
from django.core.exceptions import ObjectDoesNotExist
import django.contrib.auth.models as authmodels
from django.utils.functional import curry
import models
import tagging
import django.db.models as dm
from django import forms
from django.http import HttpResponseRedirect
from django.shortcuts import render_to_response

from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin

import django.db.models as django_models

import logging

log = logging.getLogger("admin")


# NOTE: adding flatpages TinyMCE configuration here

from django.contrib.flatpages.models import FlatPage
from django.contrib.flatpages.admin import FlatPageAdmin as FPAdminOld

from tinymce.widgets import TinyMCE

class FlatPageAdmin(FPAdminOld):
    class Media:
        js = ('js/tiny_mce/tiny_mce.js','js/tiny_mce/textareas.js',)
    

admin.site.unregister(FlatPage)
admin.site.register(FlatPage,FlatPageAdmin)

class FeaturedWorkAdmin(admin.ModelAdmin):
    formfield_overrides = {
        django_models.CharField: { 'widget' : forms.Textarea }
    }

class CollectionAdmin(admin.ModelAdmin):
    prepopulated_fields = { "slug" : ("name",) }
    actions=['really_delete_selected']
    
    def get_actions(self, request):
        actions = super(CollectionAdmin, self).get_actions(request)
        del actions['delete_selected']
        return actions
    
    def really_delete_selected(self, request, queryset):
        for obj in queryset:
            obj.delete()
        
        if queryset.count() == 1:
            message_bit = "1 collection was"
        else:
            message_bit = "%s collections were" % queryset.count()
        
        self.message_user(request, "%s successfully deleted")
    really_delete_selected.short_description = "Delete selected collections"
            
class WorkAdmin(admin.ModelAdmin):
    prepopulated_fields = { "slug" : ("title",) }
    actions = ['bulk_delete', 'bulk_available', 'bulk_add_to_collection']
    filter_horizontal = ('subjects',)
    list_display = ('id', 'title', 'collection', 'genre','author_display','isbn', 'available',)
    list_display_links = ('title',)
    readonly_fields = ('id',)
    
    tags = tagging.forms.TagField(widget=forms.CharField())
    
    def genre(self,obj):
        return obj.genre.label
    
    def get_actions(self,request):
        """
        Hide the default bulk delete, since it doesn't call
        the delete() method on the deleted instances
        """
        actions = super(WorkAdmin,self).get_actions(request)
        del actions['delete_selected']
        return actions
    
    def bulk_available(self,request,queryset):
        """Makes all the members of a queryset available for viewing"""
        for work in queryset:
            work.available = True
            work.save()
    
    bulk_available.short_description = "Make selected works available"

    def bulk_delete(self,request, queryset):
        """
        Provides a workaround for the fact that bulk deletes do not call
        the delete() method on the deleted instances.
        """
        for work in queryset:
            try:
                work.delete()
            except Exception, ex:
                print ex
    bulk_delete.short_description = "Delete selected works"
    
    class AddCollectionForm(forms.Form):
        from models import Collection
        _selected_action = forms.CharField(widget=forms.MultipleHiddenInput)
        collection = forms.ModelChoiceField(Collection.objects)

    def bulk_add_to_collection(self, request, queryset):
        form = None
        
        if 'apply' in request.POST:
            form = self.AddCollectionForm(request.POST)
            
            if form.is_valid():
                collection = form.cleaned_data['collection']
                
                for work in queryset:
                    work.collection = collection
                    work.save()

                plural = ''
                if queryset.count() != 1:
                    plural = 's'
                
                self.message_user(request, "Successfully added collection %s to %d work%s" % (collection, queryset.count(), plural))
                return HttpResponseRedirect(request.get_full_path())
                
        if not form:
            form = self.AddCollectionForm(initial={'_selected_action': request.POST.getlist(admin.ACTION_CHECKBOX_NAME)})
        
        return render_to_response('admin/add_collection.html', {'works':queryset, 'collection_form': form,})
    bulk_add_to_collection.short_description = "Add selected works to a collection"

class SectionAdmin(admin.ModelAdmin):
    list_filter = ('work',)
    list_display = ('work', 'order','title','access_controlled',)
    list_display_links = ('work', 'title',)
    actions = ['bulk_lock','bulk_unlock','bulk_commentable', 'bulk_uncommentable']

    def get_actions(self,request):
        """
        Get rid of the (bulk) delete action
        since sections should only be deleted
        in bulk by deleting their associated works.
        """
        actions = super(SectionAdmin,self).get_actions(request)
        del actions['delete_selected']
        return actions

    def _acl(self,request,queryset,control=True):
        for sect in queryset:
            sect.access_controlled = control
            sect.save()

    bulk_lock = curry(_acl,control=True)
    bulk_lock.short_description = "Control Access to selected sections"
    bulk_unlock = curry(_acl,control=False)
    bulk_unlock.short_description = "Open Access for selected sections"

    def _comment(self,request,queryset,commentable=True):
        for sect in queryset:
            sect.accepts_comments = commentable
            sect.save()
    bulk_commentable = curry(_comment,commentable=True)
    bulk_commentable.short_description = "Open selected sections for comments"

    bulk_uncommentable = curry(_comment,commentable=False)
    bulk_uncommentable.short_description = "Close selected sections for comments"

# Inlines allow the profile object to be edited
# along with the basic User object

class UserAccountInline(admin.StackedInline):
    model = models.UserAccount
    fk_name = 'user'
    max_num = 1
    
        
class UserAccountAdmin(UserAdmin):
    ordering = ('-date_joined',)
    list_filter = ('is_active', 'is_staff',)
    list_display = ('username', 'first_name', 'last_name', 'email', 'is_active','date_joined','list_groups',)
    #list_editable = ('groups',)
    inlines = [UserAccountInline,]
    actions = ['give_premium_access', 'remove_premium_access']

    def give_premium_access(self, request, queryset):
       try:
           message_bit = ''
           user_count = 0
           for user in queryset:
               user.groups.add(authmodels.Group.objects.get(name__exact='Premium Account'))
               if(user_count != 0):
                   message_bit += ", "
               message_bit += "%s" % user
               user_count = user_count+1
           if user_count == 1:
               message_bit += " is in the Premium Account group"
           else:
               message_bit += " are in the Premium Account group"
       except ObjectDoesNotExist:
           message_bit = "Oops!  We could not find the group 'Premium Account'."
       self.message_user(request, "%s" % message_bit)
    give_premium_access.short_description = "Add selected to Premium Account group"

    def remove_premium_access(self, request, queryset):
        try:
            message_bit = ''
            user_count = 0
            for user in queryset:
                user.groups.remove(authmodels.Group.objects.get(name__exact='Premium Account'))
                if(user_count != 0):
                    message_bit += ", "
                message_bit += "%s" % user
                user_count = user_count+1
            if user_count == 1:
                message_bit += " is not in the Premium Account group"
            else:
                message_bit += " are not in the Premium Account group"
        except ObjectDoesNotExist:
            message_bit = "Oops! We couldn't find the group 'Premium Account'."
        self.message_user(request, "%s" % message_bit)
    remove_premium_access.short_description = "Remove selected from Premium Account group"

    def list_groups(self,obj):
        group_list_string = ''
        for i, group in enumerate(obj.groups.all()):
            if i > 0:
                group_list_string += ', '
            group_list_string += str(group)

        return group_list_string
    list_groups.short_description = "Account Type"
    
admin.site.register(models.Work, WorkAdmin)

class BlogEntryAdmin(admin.ModelAdmin):
    class Media:
        js = ('js/tiny_mce/tiny_mce.js',) #'js/tiny_mce/textareas.js',)
    formfield_overrides = {
        dm.TextField: { 'widget' : TinyMCE },
        }
        
#admin.site.register(models.BlogEntry, BlogEntryAdmin)
#admin.site.register(models.Format)
admin.site.register(models.Genre)
admin.site.register(models.Section,SectionAdmin)

admin.site.register(models.Publisher)
admin.site.register(models.ExternalURL)

# register inline editor for user objects
admin.site.unregister(User)
admin.site.register(User, UserAccountAdmin)

admin.site.register(models.NamedPerson)
admin.site.register(models.WorkAuthoring)
admin.site.register(models.FeaturedWork, FeaturedWorkAdmin)
admin.site.register(models.License)
admin.site.register(models.Collection, CollectionAdmin)

