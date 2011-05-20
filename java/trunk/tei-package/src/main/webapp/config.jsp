<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib prefix="local" tagdir="/WEB-INF/tags" %>
<!DOCTYPE html>
<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<script type="text/javascript" src="${ctxPath}/js/jquery-1.3.2.min.js"></script>
<script type="text/javascript" src="${ctxPath}/js/jquery.validate.pack.js"></script>
<script type="text/javascript" src="${ctxPath}/js/jquery.blockUI.js"></script>
<link rel="stylesheet" href="${ctxPath}/css/styles.css" type="text/css" />
<title>Packager Configuration</title>
</head>
<body>
<c:set var="request" value="${pageContext.request}"/>
<local:navigation/>
 <c:set var="config" value="${requestScope.config}"/>
 <h1>Configuration</h1>
  <c:if test="${ requestScope.changedAttribute != null }">
   <div class="message">
   	${ requestScope.changedAttribute  }
   	</div>
  </c:if>
 <form action="." method="POST">
 <table>
  <thead>
  <tr>
  	<th>Name</th>
  	<th>Value</th>
  </tr>
  </thead>
  <tbody>
   <tr>
   	<td>XProc/XSLT Locations (Comma-separated)</td>
   	<td><textarea id="assetLocations" name="assetLocations" rows="3" cols="40">${config.assetLocationString}</textarea></td>
  </tr>
   <tr>
   	<td>UploadDirectory</td>
   	<td> ${ config.uploadDirectory.absolutePath }</td>
  </tr>
  
  </tbody>
  <tfoot>
  <tr>
  	<td colspan="2"><input type="submit"/></td>
  </tr>
  </tfoot>
 </table>
 </form>

</body>
</html>