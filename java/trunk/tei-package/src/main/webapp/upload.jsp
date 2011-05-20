<%@ page language="java" contentType="text/html; charset=UTF-8"
import="edu.unc.lib.web.SessionFilter"
    pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="local" tagdir="/WEB-INF/tags" %>
<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Upload Complete</title>
<link rel="stylesheet"
 	href="${ctxPath}/css/styles.css"
 	type="text/css" />
<style type="text/css">
	#uploadInfo {
		margin: auto;
		width: 30%;
		background-color: #eee;
		padding: .5em;
	}
	
	#uploadInfo > h3 {
		background-color: #9cc;
		border-bottom: 2px solid #000;
		padding: .2em .5em;
		margin: 0;
		text-align: center;
	}
	
	.download {
		padding: 1em;
	}
	
	.download:hover {
		cursor: pointer;
	}
		
	.download a {
		border: 0;
		float: left;
	}
	
	.download a img {
		border-style: none;
	}
	
	.download .instructions {
		float: left;
		padding-left: 1em;
		vertical-align: top;
	}
 </style>
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
 <c:set var="event" value="${ requestScope.uploadEvent }"/>
 <div id="uploadInfo">
 	<h3>Processing Complete</h3>
 	<div class="details">
 	 <div class="download">
 		<a href="${ ctxPath }/session/${ event.id }/ingest.zip"
 			id="ingestable"
 	 title="Download ingest package"><img src="${ctxPath}/images/download.png" height="64" width="64"
 	 	alt="Download"/></a> 
 	 	<div class="instructions">
 	 	 <h3>Download Ingest Package</h3>
 	 	 <p>${ event.resultFileSize }</p> 
 	 	</div>
 	 	<div style="clear: both;"></div>
 	 	</div>
 	<ul>
 	 
 	 <li>Original File: ${ event.originalName }</li>
 	 <li>MIME type: ${ event.mimeType }</li>
 	 <li>Size: ${ event.uploadedFileSize }</li>
 	</ul>
 	  <p>You can download the ingest package now by clicking on 
 	  the "Download Ingest Package" icon above, or you can <a href="${ctxPath}">continue uploading</a>.
 	  When you are done, you can see and download all the ingest packages you've created during the current
 	  session <a href="${ctxPath}/session/">here</a> or by following the "Session" at 
 	  the top of any page.</p>
 	</div>
 </div> 
</body>
</html>