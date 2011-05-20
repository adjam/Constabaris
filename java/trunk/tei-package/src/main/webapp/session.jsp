<?xml version="1.0" encoding="UTF-8" ?>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="local" tagdir="/WEB-INF/tags" %>
<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link href="${ pageContext.request.contextPath }/css/styles.css" 
	type="text/css" rel="stylesheet" />
<title>Session Files</title>
</head>
<body>
 <local:navigation/>
 <c:set var="uploadSession" value="${ requestScope.uploadSession }"/>
   <table width="85%">
	 <thead>
	  <tr>
	   <th title="Link to download ingest package">Ingest Package</th>
	   <th title="Name on your hard drive of the uploaded file">Original Name</th>
	   <th title="Original size of the uploaded file">Original Size (bytes)</th>
	   <th title="Time the file was uploaded">Time</th>
	   <th title="Checksum for uploaded file">Checksum</th>
	  </tr>
	 </thead>
	 <tbody>
	<c:forEach items="${ uploadSession.events }" var="event">
		<tr>
		    <td><a href="${ctxPath}/session/${event.id }/ingest.zip" border="0"><img src="${ctxPath}/images/application_get.png" alt="Download" /> Download</a></td>
			<td><a href="${ctxPath}/session/${ event.id  }/${event.originalName }?original=true" title="download original file">${ event.originalName }</a></td>
			<td>${event.uploadedFileSize }</td>
			<td>${ event.timestampAsDate }</td>
			<td>${ event.checksumAsString }</td>
		</tr>
	</c:forEach>
	</tbody>
  </table>
  <p>Don't count on your files being available after you log out!</p>
</body>
</html>