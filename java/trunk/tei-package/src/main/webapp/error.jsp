<%@ page language="java" contentType="text/html; charset=UTF-8"
isErrorPage="true"
    pageEncoding="UTF-8"%>
   <%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
   <%@taglib prefix="local" tagdir="/WEB-INF/tags" %>
	<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
	<c:set var="request" value="${pageContext.request}"/>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="stylesheet" href="${ctxPath}/css/styles.css" 
 type="text/css" />
<title>Processing Error</title>
</head>
<body>
<local:navigation/>
 <h1>Processing Error</h1>
 <p>Sorry, but processing of your request hit a snag that the system doesn't know how
 to deal with.  This may not be your fault.</p>
 
 <pre class="stackTrace">${ requestScope.stackTrace }</pre>

</body>
</html>