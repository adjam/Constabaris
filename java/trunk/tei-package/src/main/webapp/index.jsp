<%@page language="java" contentType="text/html; charset=utf-8"
pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="local" tagdir="/WEB-INF/tags" %>
<!DOCTYPE html>
<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>TEI Ingest</title>
<meta charset="utf-8" />
<script type="text/javascript" src="${ctxPath}/js/jquery-1.3.2.min.js"></script>
<script type="text/javascript" src="${ctxPath}/js/jquery.validate.pack.js"></script>
<script type="text/javascript" src="${ctxPath}/js/jquery.blockUI.js"></script>
<link rel="stylesheet" href="${ctxPath}/css/styles.css" type="text/css" />

<script type="text/javascript">

	$(document).ready( function() {
		$("#uploadForm").validate();
		$("#uploadForm").submit( function() {
			if ( $(this).valid() ) {
				$.blockUI( { 
						message:  'Processing Upload, please wait',
						css : {
						border: 'none',
						cursor: 'wait',
						padding: '5em',
						fontSize: '150%',
						fontWeight: 'bold',
						backgroundColor: '#000',
						'-webkit-border-radius' : '10px',
						'-moz-border-radius' : '10px',
						opacity: .5,
						color: '#fff'
				} }); // blockUI
			} // if valid
		}); // uploadForm submit handler
	}); // document.ready
</script>
 	
</head>
<body>
<c:set var="request" value="${pageContext.request}"/>
<local:navigation/>
<h1>TEI Ingest</h1>
<div class="form">
<form id="uploadForm"
 enctype="multipart/form-data" method="POST" action="${ctxPath}/ingest/">
<fieldset><legend>Upload</legend> 
<div class="formRow"><label for="fileInput">File</label>
<br />
<input type="file" name="file" id="fileInput"
	class="required"
	title="Please enter a TEI P5 .xml or .zip file" /></div>
	<input type="hidden" name="store" value="true" /> <br />
<input type="submit" name="action" value="Upload" />
</fieldset>
</form>
</div>
<div class="centered">
	<p>Use the upload form to create an ingest package.  Alternately, you may simply POST a TEI P5 xml or zip file to 
	<samp>${ ctxPath }/service/</samp>, along with the appropriate 
	content-type header.  e.g. if you are using <kbd>curl</kbd>, the following should
	produce an appropriate result:	
	</p>
	<pre>curl -X POST --data-binary @myteifile.xml -H"Content-Type: application/xml" \
	-o ingest.zip http://${request.serverName}:${request.serverPort}${ctxPath}/service/</pre>
	<p>See the <a href="${ctxPath}/about.jsp">“about” page</a> for more details.</p>
</div>
</body>
</html>