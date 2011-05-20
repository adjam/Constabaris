<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:svrl="http://purl.oclc.org/dsdl/svrl" xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="#all" version="2.0">
	<xsl:output method="xml" encoding="utf-8" indent="yes"
		doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
		doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>

	<xsl:template match="svrl:schematron-output">
		<html>
			<head>
				<title>UNC Press :: Monograph Schematron</title>

				<style type="text/css">
					div.main {
						margin-left: 20px;
						clear: both;
					}
					div.logo {
						float: left;
					}
					div.header {
						float: left;
						margin-left: 100px;
					}
					table.reports {
						background: #ECF8E0;
						border-collapse: collapse;
						clear: both;
					}
					table.reports th, table.reports td {
						border: 1px silver solid;
						padding: 0.2em;
					}
					table.reports th {
						background: #9acd32;
						text-align: left;
					}
					table.results caption {
						margin-left: inherit;
						margin-right: inherit;
					}
					table.priority1 {
						background: #F5A9A9;
						border-collapse: collapse;
					}
					table.priority1 th, table.priority1 td {
						border: 1px silver solid;
						padding: 0.2em;
					}
					table.priority1 th {
						background: #FE2E2E;
						text-align: left;
					}
					table.priority1 caption {
						margin-left: inherit;
						margin-right: inherit;
					}
					table.priority2 {
						background: #F2F5A9;
						border-collapse: collapse;
					}
					table.priority2 th, table.priority2 td {
						border: 1px silver solid;
						padding: 0.2em;
					}
					table.priority2 th {
						background: #ffff33;
						text-align: left;
					}
					table.priority2 caption {
						margin-left: inherit;
						margin-right: inherit;
					}</style>
			</head>
			<body>
				<div class="main">
					<div class="logo">
						<img alt="logo" src="/Users/reed/documents/schematron/unc_logo.png"/>
					</div>
					<div class="header">
						<h2>Title Schematron Results</h2>
					</div>
					<table width="1200" class="reports">
						<tr>
							<th colspan="3">Reports</th>
						</tr>
						<xsl:for-each select="svrl:successful-report">
							<xsl:choose>
								<xsl:when test="@role='links'">
									<tr>
										<td style="width:5%">
											<xsl:value-of select="@id"/>
										</td>
										<td style="width:60%">

											<!--<xsl:choose>
												<xsl:when test="starts-with(normalize-space(string(.)), 'oclc:')">
													<a onclick="target='_blank';">
														<xsl:attribute name="href">
															<xsl:value-of select="concat('http://www.worldcat.org/oclc/', normalize-space(substring-after(., 'oclc:')))"/>
														</xsl:attribute>
														<xsl:value-of select="svrl:text"/>
													</a>
												</xsl:when>
												<xsl:otherwise>-->
													<a onclick="target='_blank';">
														<xsl:attribute name="href">
															<xsl:value-of select="normalize-space(current())"/>
														</xsl:attribute>
														<xsl:value-of select="svrl:text"/>
													</a>
<!--												</xsl:otherwise>
											</xsl:choose>-->
										</td>
										<td style="width:35%">
											<xsl:value-of select="@location"/>
										</td>
									</tr>
								</xsl:when>
								<xsl:when test="@role='permissions'">
									<tr>
										<td style="width:5%">
											<xsl:value-of select="@id"/>
										</td>
										<td style="width:60%">
											<xsl:value-of select="svrl:text"/>
										</td>
										<td style="width:35%">
											<xsl:value-of select="@location"/>
										</td>
									</tr>
								</xsl:when>
								<xsl:otherwise>
									<tr>
										<td style="width:5%">
											<xsl:value-of select="@id"/>
										</td>
										<td style="width:60%">
											<xsl:value-of select="svrl:text"/>
										</td>
										<td style="width:35%">
											<xsl:value-of select="@location"/>
										</td>
									</tr>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</table>
					<table width="1200" class="priority1">
						<tr>
							<th colspan="3">Priority 1: Failed Asserts</th>
						</tr>
						<xsl:for-each select="svrl:failed-assert[@role='Priority1']">
							<tr>
								<td style="width:5%">
									<xsl:value-of select="@id"/>
								</td>
								<td style="width:60%">
									<xsl:value-of select="svrl:text"/>
								</td>
								<td style="width:35%">
									<xsl:value-of select="@location"/>
								</td>
							</tr>
						</xsl:for-each>
					</table>
					<table width="1200" class="priority2">
						<tr>
							<th colspan="3">Priority 2: Failed Asserts</th>
						</tr>
						<xsl:for-each select="svrl:failed-assert[@role='Priority2']">
							<tr>
								<td style="width:5%">
									<xsl:value-of select="@id"/>
								</td>
								<td style="width:60%">
									<xsl:value-of select="svrl:text"/>
								</td>
								<td style="width:35%">
									<xsl:value-of select="@location"/>
								</td>
							</tr>
						</xsl:for-each>
					</table>
					<p>© 2008 <a href="http://uncpress.unc.edu/"
						>The University of North Carolina Press</a></p>
				</div>
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>
