from django.contrib import admin
import models

class AnnotationAdmin(admin.ModelAdmin):
    list_display = ('submit_date', 'user', 'comment', 'is_approved', 'content_object')
    list_display_links = ('submit_date', 'comment', 'is_approved')
    ordering = ('-submit_date', '-approved_date')

    actions = ['bulk_approve']

    date_hierarchy = 'submit_date'
    exclude = ('site',)
    readonly_fields = ('user', 'user_name', 'work', 'ip_address', 'content_internal_path')
    fieldsets = (
        (None, {'fields': ('user', 'work', 'content_internal_path', 'comment', 'approved_date'), 'classes': ('wide')}),
        ('User Info', {'fields': ('user_name', 'ip_address', 'user_url'), 'classes': ('collapse',)}),
        ('Comment Metadata', {'fields': ('is_public', 'is_removed', 'format', 'tags', 'genre'), 'classes': ('collapse',)}),
    )

    def bulk_approve(self,request, queryset):
        """Calls the .approve() method on all the annotations (which
		handles updating user records as well).
        """
        for ann in queryset:
            try:
                ann.approve()
            except Exception, ex:
                print ex
    bulk_approve.short_description = "Approve selected annotations"


    class Media:
           js = ("js/jquery-1.4.2.min.js", "js/plugins/approved_date_to_checkbox.js",)


admin.site.register(models.Annotation, AnnotationAdmin)
admin.site.register(models.Format)
