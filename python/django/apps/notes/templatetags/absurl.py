from django import template
from django.template.defaulttags import URLNode,url
from django.contrib.sites.models import Site
import urlparse

register = template.Library()

__doc__ = """Provides an absurl template tag that works like the standard ``url`` template tag, except that it adds the scheme and server name.  Usage is the same as for the ``url`` tag."""

class AbsoluteURLNode(URLNode):
	def render(self,context):
		path = super(AbsoluteURLNode,self).render(context)
		result = ""
		if 'request' in context:
			rq = context['request']
			result = rq.build_absolute_uri(path)
		else:
			domain = Site.objects.get_current().domain
			result = urlparse.urljoin("http://%s" % domain,path)
		if self.asvar:
			context[self.asvar] = result
			return ""
		return result
		
		

def absurl(parser,token,node_cls=AbsoluteURLNode):
	instance = url(parser,token)
	return node_cls(view_name=instance.view_name,args=instance.args,kwargs=instance.kwargs,asvar=instance.asvar)

absurl = register.tag(absurl)
