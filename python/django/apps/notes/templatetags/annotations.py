from django import template
from django.conf import settings
from apps.notes.conf import settings as notes_settings
from django.utils.encoding import smart_unicode
from apps.notes.forms import AnnotationForm
from apps.notes.models import Annotation
from django.contrib.comments.templatetags.comments import CommentListNode
from django.contrib.comments.models import Comment
from django.contrib.auth.models import User

register = template.Library()

import logging

log = logging.getLogger("notes.template_tags.annotations")

def show_comment(context):
    return context

register.inclusion_tag("comment.html",takes_context=True)(show_comment)

def note_form(form,section):
    return { 'form' : form, 'next' : section.get_absolute_url() }

register.inclusion_tag('form.html')(note_form)

class ModerationCommentNode(CommentListNode):
    """
    Subclass of CommentListNode that allows display of comments that are not 
    public.
    """
    def __init__(self,ctype=None,object_pk_expr=None,object_expr=None,as_varname=None,comment=None,moderation=True):
        super(CommentListNode,self).__init__(ctype,object_pk_expr,object_expr,as_varname,comment)
        self.moderation = moderation

    def get_query_set(self,context):
        # essentially, recreate superclass' implementation except that
        # for moderators, we want to return non-public comments.
        if not self.moderation:
            return super(ModerationCommentNode,self).get_query_set(context)
        ctype,object_pk = self.get_target_ctype_pk(context)
        if not object_pk:
            return self.comment_model.objects.none()
        qs = self.comment_model.objects.filter(
            content_type = ctype,
            object_pk = smart_unicode(object_pk),
            site = settings.SITE_ID,
        )

        if notes_settings.COMMENTS_HIDE_REMOVED:
            qs = qs.filter(is_removed=False)
        return qs

def get_comment_list(parser,token):
    log.debug('get_comment_list'+str(token))
    return ModerationCommentNode.handle_token(parser,token)

register.tag(get_comment_list)

class UserAnnotationNode(template.Node):
    def __init__(self, var_name):
        log.debug('UserCommentNode.__init__')
        self.var_name = var_name
    
    def render(self, context):
        log.debug('UserAnnotationNode.render')
        annotations = Annotation.objects.filter(user=context['profile'].user)
        context[self.var_name] = annotations
        return ''  

def get_user_annotations(parser, token):
    log.debug('get_user_annotations')
    try:
        tag_name, _as, var_name = token.split_contents()
    except ValueError:
        raise template.TemplateSyntaxError, "%r tag requires two arguments" % token.contents.split()[0]
    return UserAnnotationNode(var_name)

register.tag(get_user_annotations)

class IfInNode(template.Node):
    '''
    Like {% if %} but checks for the first value being in the second value (if a list). Does not work if the second value is not a list.
    '''
    def __init__(self, var1, var2, nodelist_true, nodelist_false, negate):
        self.var1, self.var2 = var1, var2
        self.nodelist_true, self.nodelist_false = nodelist_true, nodelist_false
        self.negate = negate

    def __str__(self):
        return "<IfNode>"

    def render(self, context):
        val1 = template.resolve_variable(self.var1, context)
        val2 = template.resolve_variable(self.var2, context)
        try:
            val2 = list(val2)
            if (self.negate and val1 not in val2) or (not self.negate and val1 in val2):
                return self.nodelist_true.render(context)
            return self.nodelist_false.render(context)
        except TypeError:
            return ""

def ifin(parser, token, negate):
    bits = token.contents.split()
    if len(bits) != 3:
        raise template.TemplateSyntaxError, "%r takes two arguments" % bits[0]
    end_tag = 'end' + bits[0]
    nodelist_true = parser.parse(('else', end_tag))
    token = parser.next_token()
    if token.contents == 'else':
        nodelist_false = parser.parse((end_tag,))
        parser.delete_first_token()
    else: nodelist_false = template.NodeList()
    return IfInNode(bits[1], bits[2], nodelist_true, nodelist_false, negate)

register.tag('ifin', lambda parser, token: ifin(parser, token, False))

