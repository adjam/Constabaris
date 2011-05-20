<%@ tag language="java" pageEncoding="UTF-8"
 	body-content="scriptless"%>
 	<%@ attribute name="page" required="false" %>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctxPath" value="${ pageContext.request.contextPath }"/>
<header>
<nav>
 <ul>
 	<li><a href="${ctxPath}/" title="Main screen of application">Main</a></li>
 	<li><a href="${ctxPath }/session/" title="View Session Uploads">Session</a></li>
 	<li><a href="${ctxPath}/about.jsp" title="About and minimal help screens">Help/About</a></li>
 	<li class="logout" title="Terminate current session; deletes all your saved work!"><a href="${ctxPath}/logout">Log Out</a></li>
 </ul>
 <div class="clearblock">&#160;</div>
 </nav>
 </header>
