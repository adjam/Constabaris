<%@ page language="java" contentType="text/html; charset=UTF-8"
	import="edu.unc.lib.web.SessionFilter"
    pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="local" tagdir="/WEB-INF/tags" %>
<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
<c:set var="request" value="${pageContext.request}"/>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<meta charset="utf-8" />
<title>About</title>
<link rel="stylesheet"
 	href="${ctxPath}/css/styles.css"
 	type="text/css" />

 <script src="${ctxPath}/js/jquery-1.3.2.min.js"></script>
 <script src="${ctxPath}/js/jquery.corner.js"></script>
 <script type="text/javascript">
 	$(document).ready( function() {
 		$("#uploadInfo .instructions").click(
 		 		function() {
 	 		 		window.location = $("#ingestable").attr("href");
 		 		})
 	});
  </script>
 
</head>
<body>
<local:navigation/>
 <div id="wrapper">
 <h1>About</h1>
  <p>This application provides development support to the Long Civil Rights Movement project.
   It accepts two types of file:
   <ul>
    <li>XML documents encoded using the TEI P5 Guidelines, with modifications by Kenneth Reed pf
    the UNC Press [ url forthcoming ]</li>
    <li>.zip archives containing such documents and linked media files (e.g. images referred to in the 
    TEI content).</li>
  </p>
  <p>
   It produces "Ingest Packages", <samp>.zip</samp> archives containing METS, generated HTML, and associated
   image files.  These files can then be uploaded directly into the LCRM application.
  </p>
   <h2>Errors Etc.</h2>
   <p>Error handling is minimal in this application.  Generally, you're getting back raw results and default
   error pages.  If a long Java stack trace is involved, that generally means either your input was bad in some way
   (not well formed XML, perhaps?) or that Adam messed up.  Generally, in this case the right thing to do is, if you
   can understand the error message, see if it looks like it was your fault.  Otherwise, cut and paste all the Java
   stack trace and send it to Adam so he can look at it.</p>
   <p>Specific errors you may encounter:
   <ul>
    <li><em>Method [GET,POST,PUT] not supported by this URL</em> - some URLs require that you POST or PUT data to them;
    if you perform a GET (e.g. cut-and-paste the URL from elsewhere into your browser's location window),
    you'll see this message.</li>
    <li><em>ZIP file must have at least one entry</em> -- generally, the processor says, "if it's not XML, then I'm going to 
    treat it as a ZIP, whereupon it attempts to open the file you uploaded as a ZIP.  If it's not a ZIP file, then you'll probably
    see this message.  It's also possible that your ZIP file is corrupted.
    Note that the server assumes that the <samp>Content-Type</samp> header sent by your client is correct (if that fails it guesses by looking
    at the file, you sent it, and I do mean <em>guesses</em>).  Content type <samp>application/xml</samp> is treated as XML, everything else
    is treated as <samp>application/zip</samp>.
    </li>
   </ul>
  </p>
   <h2>Technologies</h2>
  <p>
	This application uses a combination of an XProc pipeline, XSLT 2.0 stylesheets, and custom Java code
   	to process the input, generate the ingestable output, and package it into ZIP archives.
  </p>
  <h2>Usage</h2>
   <p>The application supports two types of usage, one interactive, and service-based.  Interactive use is session-based,
   and allows users to upload several files in succession and have the results stored until they log out.
   </p>
   <p>Service-oriented usage involves using the HTTP POST operation to send files to the endpoint that processes them.  The HTTP response
   sent back by the server (if no error is encountered) is the ZIP contents of the ingest package.  Typical command-line usage with <samp>curl</samp>
   might go as follows:
   <div class="example">
    <h3>"Bare" TEI processing</h3>
   <pre>curl -X POST --data-binary @myteifile.xml -H"Content-Type: application/xml" \
	-o ingest.zip http://${request.serverName}:${request.serverPort}${basepath}/ingest/
   </pre>
   </div>
   <div class="example">
    <h3>ZIP archive processing</h3>
    <pre>curl -X POST --data-binary @book.zip -H"Content-Type: application/zip" \
	-o ingest.zip http://${request.serverName}:${request.serverPort}${basepath}/ingest/
   </pre>
   </div>
   <p>In both cases, the server response is saved as <samp>ingest.zip</samp> in the current directory; adjust the
   value of the <samp>-o</samp> parameter to get different results, or leave it off entirely to have the output
   go directly to the console (but why would you want that?)
   </p>
  
   
 </div> 
</body>
</html>
</html>