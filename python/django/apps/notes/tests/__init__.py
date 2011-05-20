import unittest
from django.test import TestCase
from django.test.client import Client
from notes import forms, models
from lxml import etree

HINKY_HTML = """
<head>
 <p>
 <script type="text/javascript">
  function do_something_hinky() {
	send_your_data_to_other_server();
  }
  do_something_hinky();
 </script>
 
  <a href="javascript:do_something_hinky()">Click me!</a>
   <abbr title="This will hurt you even if you do not see it" style="display:none;">TWHYEIYDNSEI</abbr>
  <ul>
	<li>What?
	<li><a href="http://www.w3.org">This link is unobjectionable ...</a>
	<img src="http://www.otherserver.com/images/poison_gif.png">
	<object>
		<param name="hey" value="you have been hacked"/>
	</object>
 </p>
"""

def get_sample_form():
	fmt = models.Format.objects.all()[0]
	return forms.AnnotationForm(fmt)
	
def get_form_data(html):
	"""
	Given the form's HTML output, gets its data as a dictionary
	"""
	doc = etree.HTML(html)
	return dict([ (x.get("name"), x.get("value"),) for x in doc.xpath("//input") ])
	self.assertTrue("security_hash" in form_data)
	
class FormSubmitTest(TestCase):
	urls = "notes.tests.urls"
	
	def __init__(self,*args,**kwargs):
		super(FormSubmitTest,self).__init__(*args,**kwargs)
		self.client = Client()

	def test_render(self):
		self.client.login(username="adamc", password="admin!")
		resp = self.client.get("/form/")
		
		if not resp.status_code == 200:
			self.fail("Got HTTP status %d" % resp.status_code )
		doc = etree.HTML(resp.content)
		form_data = get_form_data(resp.content)
		self.assertTrue("security_hash" in form_data)
		
	def is_safe(self,test_html):
		doc = etree.HTML(test_html)
		bad_tags = ['script', 'img']
		for link in doc.xpath("//a"):
			href = link.get('href', '')
			if len(href) > 0 and not (href.startswith("http://") or href.startswith("https://")):
				self.fail("Found non-empty href that doesn't start with http(s)")
		for el in doc.iterdescendants():
			if el.tag in bad_tags:
				self.fail("Found disallowed tag '%s' in cleaned HTML" % el.tag )
		return True
			
	def test_sanitize(self):
		form = get_sample_form()
		form.cleaned_data = {'comment' : HINKY_HTML}
		cleaned_value = form.clean_comment()
		self.assertTrue(self.is_safe(cleaned_value))
