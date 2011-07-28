<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:schold="http://www.ascc.net/xml/schematron"
                xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:lfn="http://lcrm.unc.edu"
                xmlns:url="java:java.net.URL"
                version="2.0"><!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
<xsl:param name="archiveDirParameter"/>
   <xsl:param name="archiveNameParameter"/>
   <xsl:param name="fileNameParameter"/>
   <xsl:param name="fileDirParameter"/>
   <xsl:variable name="document-uri">
      <xsl:value-of select="document-uri(/)"/>
   </xsl:variable>

   <!--PHASES-->


<!--PROLOG-->
<xsl:output xmlns:svrl="http://purl.oclc.org/dsdl/svrl" method="xml"
               omit-xml-declaration="no"
               standalone="yes"
               indent="yes"/>

   <!--XSD TYPES FOR XSLT2-->


<!--KEYS AND FUNCTIONS-->
<xsl:function xmlns:file="java:java.io.File" name="lfn:roman-value">
		    <xsl:param name="input" as="xs:integer"/>
		    <xsl:number value="$input" format="i"/>
	  </xsl:function>
   <xsl:function xmlns:file="java:java.io.File" name="lfn:file-exists">
		    <xsl:param name="image-path" as="xs:string"/>
		    <xsl:variable name="full-path" select="lfn:get-image-filesystem-path($filename,$image-path)"
                    as="xs:string"/>
		    <xsl:variable name="theFile" select="file:new($full-path)"/>
		
		    <xsl:choose>
			      <xsl:when test="file:exists($theFile)">
				        <xsl:message>
               <xsl:value-of select="$full-path"/> exists</xsl:message>
				        <xsl:text>1</xsl:text>
			      </xsl:when>
			      <xsl:otherwise>
				        <xsl:message>
               <xsl:value-of select="$full-path"/> not found</xsl:message>
				        <xsl:text>0</xsl:text>
			      </xsl:otherwise>
		    </xsl:choose>
	  </xsl:function>
   <xsl:function xmlns:file="java:java.io.File" name="lfn:get-image-filesystem-path">
		    <xsl:param name="base-uri" as="xs:anyURI"/>
		    <xsl:param name="relative-path" as="xs:string"/>
		    <xsl:choose>
			      <xsl:when test="starts-with($relative-path, '/')">
				        <xsl:value-of select="$relative-path"/>
			      </xsl:when>
			      <xsl:otherwise>
				        <xsl:variable name="full-uri" select="resolve-uri($relative-path, $base-uri)"/>
				        <xsl:variable name="url" select="url:new($full-uri)"/>
				        <xsl:value-of select="url:get-path($url)"/>
			      </xsl:otherwise>
		    </xsl:choose>
	  </xsl:function>

   <!--DEFAULT RULES-->


<!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<xsl:template match="*" mode="schematron-select-full-path">
      <xsl:apply-templates select="." mode="schematron-get-full-path-2"/>
   </xsl:template>

   <!--MODE: SCHEMATRON-FULL-PATH-->
<!--This mode can be used to generate an ugly though full XPath for locators-->
<xsl:template match="*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">
            <xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>*:</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>[namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="preceding"
                    select="count(preceding-sibling::*[local-name()=local-name(current())                                   and namespace-uri() = namespace-uri(current())])"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>
   <xsl:template match="@*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">@<xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>@*[local-name()='</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>' and namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--MODE: SCHEMATRON-FULL-PATH-2-->
<!--This mode can be used to generate prefixed XPath for humans-->
<xsl:template match="node() | @*" mode="schematron-get-full-path-2">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="preceding-sibling::*[name(.)=name(current())]">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-3-->
<!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
<xsl:template match="node() | @*" mode="schematron-get-full-path-3">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="parent::*">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>

   <!--MODE: GENERATE-ID-FROM-PATH -->
<xsl:template match="/" mode="generate-id-from-path"/>
   <xsl:template match="text()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
   </xsl:template>
   <xsl:template match="comment()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.@', name())"/>
   </xsl:template>
   <xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
   </xsl:template>

   <!--MODE: GENERATE-ID-2 -->
<xsl:template match="/" mode="generate-id-2">U</xsl:template>
   <xsl:template match="*" mode="generate-id-2" priority="2">
      <xsl:text>U</xsl:text>
      <xsl:number level="multiple" count="*"/>
   </xsl:template>
   <xsl:template match="node()" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>n</xsl:text>
      <xsl:number count="node()"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="string-length(local-name(.))"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="translate(name(),':','.')"/>
   </xsl:template>
   <!--Strip characters--><xsl:template match="text()" priority="-1"/>

   <!--SCHEMA SETUP-->
<xsl:template match="/">
      <svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                              title="ISO schematron file for TEI Monographs."
                              schemaVersion="ISO19757-3">
         <xsl:comment>
            <xsl:value-of select="$archiveDirParameter"/>   
		 <xsl:value-of select="$archiveNameParameter"/>  
		 <xsl:value-of select="$fileNameParameter"/>  
		 <xsl:value-of select="$fileDirParameter"/>
         </xsl:comment>
         <svrl:ns-prefix-in-attribute-values uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
         <svrl:ns-prefix-in-attribute-values uri="http://lcrm.unc.edu" prefix="lfn"/>
         <svrl:ns-prefix-in-attribute-values uri="java:java.net.URL" prefix="url"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">title.checks</xsl:attribute>
            <xsl:attribute name="name">Title Statement</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M8"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">doc.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the TEI document</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M9"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">keyword.checks</xsl:attribute>
            <xsl:attribute name="name">Checking keyword length</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M10"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">date.checks</xsl:attribute>
            <xsl:attribute name="name">date.checks</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M11"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">PrimaryID</xsl:attribute>
            <xsl:attribute name="name">PrimaryID</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M16"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">docURI</xsl:attribute>
            <xsl:attribute name="name">docURI</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M17"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">author.checks</xsl:attribute>
            <xsl:attribute name="name">Checking for @xml:id in author, as well as reg</xsl:attribute>
            <svrl:text>Author ID and reg Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M18"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">availability.checks</xsl:attribute>
            <xsl:attribute name="name">Checking for availability and attributes</xsl:attribute>
            <svrl:text>Header availability and attributes</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M19"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">lcsh.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the LCSH Keywords</xsl:attribute>
            <svrl:text>All LCSH Keyword Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M20"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">list.checks</xsl:attribute>
            <xsl:attribute name="name">Checking glossary lists for correct type</xsl:attribute>
            <svrl:text>All List type Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M21"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">UNCPkeywords.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the UNC Press Keywords</xsl:attribute>
            <svrl:text>UNCP Keywords Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M22"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">abstract.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the Abstracts</xsl:attribute>
            <svrl:text>All Abstract Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M23"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">links</xsl:attribute>
            <xsl:attribute name="name">links</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M24"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">pb.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the pb Structure</xsl:attribute>
            <svrl:text>All pb Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M25"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">pb.front</xsl:attribute>
            <xsl:attribute name="name">Checking front pb Structure</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M27"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">pb.body</xsl:attribute>
            <xsl:attribute name="name">Checking body pb Structure</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M28"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">pb.back</xsl:attribute>
            <xsl:attribute name="name">Checking back pb Structure</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M29"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">count.checks</xsl:attribute>
            <xsl:attribute name="name">Checking Counts for Elements</xsl:attribute>
            <svrl:text>All Count Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M30"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">greek.check</xsl:attribute>
            <xsl:attribute name="name">Check for Greek</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M31"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">greekextended.check</xsl:attribute>
            <xsl:attribute name="name">Check for GreekExtended</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M32"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">hebrew.check</xsl:attribute>
            <xsl:attribute name="name">Check for Hebrew</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M33"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">graphic.check</xsl:attribute>
            <xsl:attribute name="name">Check for Extant Graphics</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M36"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">graphic.Permissions.check</xsl:attribute>
            <xsl:attribute name="name">Check for Permissions on Graphics</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M37"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">id_pub.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the ID against the header</xsl:attribute>
            <svrl:text>ISBN ID check</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M39"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">id_pub.local.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the ID for proper type</xsl:attribute>
            <svrl:text>ISBN ID check</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M40"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">target.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the ref target</xsl:attribute>
            <svrl:text>All ref target Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M41"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">pb-pageref.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the ref target</xsl:attribute>
            <svrl:text>All ref target Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M42"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">pageref.id.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the page ref target</xsl:attribute>
            <svrl:text>All page ref target Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M43"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">chapter.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the chapter Structure</xsl:attribute>
            <svrl:text>All chapter Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M45"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">bibliography.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the bibliography Structure</xsl:attribute>
            <svrl:text>All bibItem Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M47"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">div.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the div Structure</xsl:attribute>
            <svrl:text>All div Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M48"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">div_head.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the div head Structure</xsl:attribute>
            <svrl:text>All div nested Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M49"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">bibl.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the bibl Structure</xsl:attribute>
            <svrl:text>All bibl nested Level Checks</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M50"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">head.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the head Structure</xsl:attribute>
            <svrl:text>Checking head for @type</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M51"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">bib.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the bibliography Structure</xsl:attribute>
            <svrl:text>Checking title for @level</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M52"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">list-type.checks</xsl:attribute>
            <xsl:attribute name="name">Checking the list Structure</xsl:attribute>
            <svrl:text>Checking list for @type</svrl:text>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M53"/>
      </svrl:schematron-output>
   </xsl:template>

   <!--SCHEMATRON PATTERNS-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">ISO schematron file for TEI Monographs.</svrl:text>
   <xsl:param name="total_pages" select="count(//tei:pb)"/>
   <xsl:param name="fm_pages" select="count(/tei:TEI/tei:text/tei:front//tei:pb)"/>
   <xsl:param name="body_pages" select="count(/tei:TEI/tei:text/tei:body//tei:pb)"/>
   <xsl:param name="bm_pages" select="count(/tei:TEI/tei:text/tei:back//tei:pb)"/>

   <!--PATTERN title.checksTitle Statement-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Title Statement</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt"
                 priority="1000"
                 mode="M8">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt"/>

		    <!--REPORT Title-->
<xsl:if test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt">
            <xsl:attribute name="id">r1</xsl:attribute>
            <xsl:attribute name="role">Title</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Title Statement: <xsl:text/>
               <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M8"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M8"/>
   <xsl:template match="@*|node()" priority="-2" mode="M8">
      <xsl:apply-templates select="*" mode="M8"/>
   </xsl:template>

   <!--PATTERN doc.checksChecking the TEI document-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the TEI document</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:text" priority="1000" mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:text"/>

		    <!--REPORT Date-->
<xsl:if test="tei:body">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:body">
            <xsl:attribute name="id">r2</xsl:attribute>
            <xsl:attribute name="role">Date</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Report date: <xsl:text/>
               <xsl:value-of select="substring(string(current-date()), 1, 10)"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M9"/>
   <xsl:template match="@*|node()" priority="-2" mode="M9">
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>

   <!--PATTERN keyword.checksChecking keyword length-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking keyword length</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:keywords[@scheme='UNCP']/tei:list/tei:item" priority="1000"
                 mode="M10">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:keywords[@scheme='UNCP']/tei:list/tei:item"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="string-length(string(.))&lt;50"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="string-length(string(.))&lt;50">
               <xsl:attribute name="id">a333</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Keyword <xsl:text/>
                  <xsl:value-of select="position()"/>
                  <xsl:text/> longer than 50 characters.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M10"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M10"/>
   <xsl:template match="@*|node()" priority="-2" mode="M10">
      <xsl:apply-templates select="*" mode="M10"/>
   </xsl:template>

   <!--PATTERN date.checks-->


	<!--RULE -->
<xsl:template match="/tei:TEI/tei:teiHeader//tei:date" priority="1000" mode="M11">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:teiHeader//tei:date"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="     string-length(normalize-space(.))=4     and string(number(substring(normalize-space(.),1,4)))!='NaN'     and string-length(substring(normalize-space(.),1,4))=4     or     string-length(normalize-space(.))=7     and string(number(substring(normalize-space(.),1,4)))!='NaN'     and string-length(substring(normalize-space(.),1,4))=4     and substring(normalize-space(.),5,1)='-'     and string(number(substring(normalize-space(.),6,2)))!='NaN'     and string-length(substring(normalize-space(.),6,2))=2     and number(substring(normalize-space(.),6,2))&gt;=1     and number(substring(normalize-space(.),6,2))&lt;=12     or      string-length(normalize-space(.))=10     and string(number(substring(normalize-space(.),1,4)))!='NaN'     and string-length(substring(normalize-space(.),1,4))=4     and substring(normalize-space(.),5,1)='-'     and string(number(substring(normalize-space(.),6,2)))!='NaN'     and string-length(substring(normalize-space(.),6,2))=2     and number(substring(normalize-space(.),6,2))&gt;=1     and number(substring(normalize-space(.),6,2))&lt;=12     and substring(normalize-space(.),8,1)='-'     and string(number(substring(normalize-space(.),9,2)))!='NaN'     and string-length(substring(normalize-space(.),9,2))=2     and number(substring(normalize-space(.),9,2))&gt;=1     and number(substring(normalize-space(.),9,2))&lt;=31     "/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="string-length(normalize-space(.))=4 and string(number(substring(normalize-space(.),1,4)))!='NaN' and string-length(substring(normalize-space(.),1,4))=4 or string-length(normalize-space(.))=7 and string(number(substring(normalize-space(.),1,4)))!='NaN' and string-length(substring(normalize-space(.),1,4))=4 and substring(normalize-space(.),5,1)='-' and string(number(substring(normalize-space(.),6,2)))!='NaN' and string-length(substring(normalize-space(.),6,2))=2 and number(substring(normalize-space(.),6,2))&gt;=1 and number(substring(normalize-space(.),6,2))&lt;=12 or string-length(normalize-space(.))=10 and string(number(substring(normalize-space(.),1,4)))!='NaN' and string-length(substring(normalize-space(.),1,4))=4 and substring(normalize-space(.),5,1)='-' and string(number(substring(normalize-space(.),6,2)))!='NaN' and string-length(substring(normalize-space(.),6,2))=2 and number(substring(normalize-space(.),6,2))&gt;=1 and number(substring(normalize-space(.),6,2))&lt;=12 and substring(normalize-space(.),8,1)='-' and string(number(substring(normalize-space(.),9,2)))!='NaN' and string-length(substring(normalize-space(.),9,2))=2 and number(substring(normalize-space(.),9,2))&gt;=1 and number(substring(normalize-space(.),9,2))&lt;=31">
               <xsl:attribute name="id">a33</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
				              <xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> does not contain a valid date (YYYY-MM-DD).
			</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M11"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M11"/>
   <xsl:template match="@*|node()" priority="-2" mode="M11">
      <xsl:apply-templates select="*" mode="M11"/>
   </xsl:template>
   <xsl:param name="filename" select="document-uri(.)"/>
   <xsl:param name="truncate" select="tokenize(document-uri(.), '/')[last()]"/>
   <xsl:param name="isbn" select="substring-before($truncate,'.')"/>
   <xsl:param name="path" select="substring-before($filename,$truncate)"/>

   <!--PATTERN PrimaryID-->


	<!--RULE -->
<xsl:template match="//tei:TEI" priority="1000" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:TEI"/>

		    <!--REPORT ID-->
<xsl:if test="@xml:id">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xml:id">
            <xsl:attribute name="id">r3</xsl:attribute>
            <xsl:attribute name="role">ID</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>The document id is <xsl:text/>
               <xsl:value-of select="@xml:id"/>
               <xsl:text/> and the filename is <xsl:text/>
               <xsl:value-of select="$truncate"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="string-length($isbn)=13"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="string-length($isbn)=13">
               <xsl:attribute name="id">a1</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The ISBN should have 13 digits: <xsl:text/>
                  <xsl:value-of select="$isbn"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="$isbn castable as xs:integer"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$isbn castable as xs:integer">
               <xsl:attribute name="id">a2</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The ISBN should have 13 digits: <xsl:text/>
                  <xsl:value-of select="$isbn"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="$isbn=substring(@xml:id,6,13)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$isbn=substring(@xml:id,6,13)">
               <xsl:attribute name="id">a111</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The ISBN in the @xml:id should match filename: <xsl:text/>
                  <xsl:value-of select="substring(@xml:id,6,13)"/>
                  <xsl:text/> does not match <xsl:text/>
                  <xsl:value-of select="$isbn"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--REPORT Count-->
<xsl:if test="//tei:pb">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="//tei:pb">
            <xsl:attribute name="id">r4</xsl:attribute>
            <xsl:attribute name="role">Count</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>There are <xsl:text/>
               <xsl:value-of select="$total_pages"/>
               <xsl:text/> pages in the data: <xsl:text/>
               <xsl:value-of select="$fm_pages"/>
               <xsl:text/> frontmatter and <xsl:text/>
               <xsl:value-of select="$body_pages+$bm_pages"/>
               <xsl:text/> body and backmatter.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M16"/>
   <xsl:template match="@*|node()" priority="-2" mode="M16">
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>

   <!--PATTERN docURI-->


	<!--RULE -->
<xsl:template match="//tei:TEI" priority="1000" mode="M17">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:TEI"/>

		    <!--REPORT docURI-->
<xsl:if test="@xml:id">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xml:id">
            <xsl:attribute name="id">r5</xsl:attribute>
            <xsl:attribute name="role">docURI</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
				           <xsl:text/>
               <xsl:value-of select="$filename"/>
               <xsl:text/>
			         </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M17"/>
   <xsl:template match="@*|node()" priority="-2" mode="M17">
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>

   <!--PATTERN author.checksChecking for @xml:id in author, as well as reg-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking for @xml:id in author, as well as reg</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt//tei:author"
                 priority="1000"
                 mode="M18">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt//tei:author"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="@xml:id"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xml:id">
               <xsl:attribute name="id">a44</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Author must have @xml:id</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="tei:reg"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:reg">
               <xsl:attribute name="id">a45</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Author must have regularized name</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="tei:name/tei:forename"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:name/tei:forename">
               <xsl:attribute name="id">a46</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Author must have forename</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="tei:name/tei:surname"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:name/tei:surname">
               <xsl:attribute name="id">a47</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Author must have surname</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="tei:name/tei:forename[1][@type='given']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="tei:name/tei:forename[1][@type='given']">
               <xsl:attribute name="id">a48</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Author forename must have @type='given'</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M18"/>
   <xsl:template match="@*|node()" priority="-2" mode="M18">
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>

   <!--PATTERN availability.checksChecking for availability and attributes-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking for availability and attributes</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt" priority="1000"
                 mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="tei:availability"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:availability">
               <xsl:attribute name="id">a39</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Availability statement for graphics must be present</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="tei:availability[@xml:id='notCleared']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="tei:availability[@xml:id='notCleared']">
               <xsl:attribute name="id">a40</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Availability statement with @xml:id=notCleared must be present</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="tei:availability[@status='restricted']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="tei:availability[@status='restricted']">
               <xsl:attribute name="id">a41</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Availability statement with @status=restricted must be present</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M19"/>
   <xsl:template match="@*|node()" priority="-2" mode="M19">
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>

   <!--PATTERN lcsh.checksChecking the LCSH Keywords-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the LCSH Keywords</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:keywords[@scheme='LCSH']" priority="1000" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:keywords[@scheme='LCSH']"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="tei:list/tei:item"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:list/tei:item">
               <xsl:attribute name="id">a3</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>LCSH keywords must be present</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M20"/>
   <xsl:template match="@*|node()" priority="-2" mode="M20">
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>

   <!--PATTERN list.checksChecking glossary lists for correct type-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking glossary lists for correct type</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:label" priority="1000" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:label"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="parent::tei:list[@type='gloss']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="parent::tei:list[@type='gloss']">
               <xsl:attribute name="id">a77</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Label elements must be in lists with type gloss.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M21"/>
   <xsl:template match="@*|node()" priority="-2" mode="M21">
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>

   <!--PATTERN UNCPkeywords.checksChecking the UNC Press Keywords-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the UNC Press Keywords</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:keywords[@scheme='UNCP']" priority="1000" mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:keywords[@scheme='UNCP']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="tei:list/tei:item"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:list/tei:item">
               <xsl:attribute name="id">a56</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>UNCP keywords must be present</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M22"/>
   <xsl:template match="@*|node()" priority="-2" mode="M22">
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>

   <!--PATTERN abstract.checksChecking the Abstracts-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the Abstracts</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:note[@type='abstract']" priority="1000" mode="M23">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:note[@type='abstract']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="tei:p"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:p">
               <xsl:attribute name="id">a11</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Text does not have an abstract.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M23"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M23"/>
   <xsl:template match="@*|node()" priority="-2" mode="M23">
      <xsl:apply-templates select="*" mode="M23"/>
   </xsl:template>

   <!--PATTERN links-->


	<!--RULE -->
<xsl:template match="//tei:note[@type='links']/tei:ref[@target]" priority="1000" mode="M24">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:note[@type='links']/tei:ref[@target]"/>

		    <!--REPORT links-->
<xsl:if test="(@target)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@target)">
            <xsl:attribute name="id">r66</xsl:attribute>
            <xsl:attribute name="role">links</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
				           <xsl:text/>
               <xsl:value-of select="(@target)"/>
               <xsl:text/>
			         </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M24"/>
   <xsl:template match="@*|node()" priority="-2" mode="M24">
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>

   <!--PATTERN pb.checksChecking the pb Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the pb Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:pb" priority="1000" mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:pb"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="ancestor::tei:div|ancestor::tei:titlePage"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ancestor::tei:div|ancestor::tei:titlePage">
               <xsl:attribute name="id">a4</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All pb elements should be contained within divs.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@xml:id)=concat('pg',@n)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@xml:id)=concat('pg',@n)">
               <xsl:attribute name="id">a5</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The pb id should have the following structure: pg{pageNo}: <xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="substring-after(@xml:id,'pg')=(@n)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="substring-after(@xml:id,'pg')=(@n)">
               <xsl:attribute name="id">a6</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The id page number should be the same as the n page number: check the id (<xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/>) against n (<xsl:text/>
                  <xsl:value-of select="@n"/>
                  <xsl:text/>).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="not(parent::tei:list)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(parent::tei:list)">
               <xsl:attribute name="id">a9</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All pb elements cannot be direct children of list; move <xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/> to item.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="not(parent::tei:listBibl)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(parent::tei:listBibl)">
               <xsl:attribute name="id">a10</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All pb elements cannot be direct children of listBibl; move <xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/> to bibl.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="not(following-sibling::*[1][self::tei:pb])"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="not(following-sibling::*[1][self::tei:pb])">
               <xsl:attribute name="id">a100</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>Check to see if <xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/> is blank in the source. </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M25"/>
   <xsl:template match="@*|node()" priority="-2" mode="M25">
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>

   <!--PATTERN pb.frontChecking front pb Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking front pb Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:text[1]/tei:front[1]//tei:pb" priority="1000" mode="M27">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:text[1]/tei:front[1]//tei:pb"/>
      <xsl:variable name="folio"
                    select="lfn:roman-value(count(preceding::tei:pb[ancestor::tei:front]) + 1)"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@n)=$folio"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@n)=$folio">
               <xsl:attribute name="id">a7</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>pb elements should be numbered sequentially: <xsl:text/>
                  <xsl:value-of select="@n"/>
                  <xsl:text/> should be <xsl:text/>
                  <xsl:value-of select="$folio"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M27"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M27"/>
   <xsl:template match="@*|node()" priority="-2" mode="M27">
      <xsl:apply-templates select="*" mode="M27"/>
   </xsl:template>

   <!--PATTERN pb.bodyChecking body pb Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking body pb Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:text[1]/tei:body[1]//tei:pb" priority="1000" mode="M28">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:text[1]/tei:body[1]//tei:pb"/>
      <xsl:variable name="folio" select="count(preceding::tei:pb[ancestor::tei:body]) + 1"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@n)=$folio"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@n)=$folio">
               <xsl:attribute name="id">a8</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>pb elements should be numbered sequentially: <xsl:text/>
                  <xsl:value-of select="@n"/>
                  <xsl:text/> should be <xsl:text/>
                  <xsl:value-of select="$folio"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M28"/>
   <xsl:template match="@*|node()" priority="-2" mode="M28">
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>

   <!--PATTERN pb.backChecking back pb Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking back pb Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:text[1]/tei:back[1]//tei:pb" priority="1000" mode="M29">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:text[1]/tei:back[1]//tei:pb"/>
      <xsl:variable name="folio_body" select="count(/tei:TEI/tei:text/tei:body//tei:pb)"/>
      <xsl:variable name="folio_bm"
                    select="$folio_body + (count(preceding::tei:pb[ancestor::tei:back]) + 1)"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@n)=$folio_bm"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@n)=$folio_bm">
               <xsl:attribute name="id">a79</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>pb elements should be numbered sequentially: <xsl:text/>
                  <xsl:value-of select="@n"/>
                  <xsl:text/> should be <xsl:text/>
                  <xsl:value-of select="$folio_bm"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M29"/>
   <xsl:template match="@*|node()" priority="-2" mode="M29">
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>

   <!--PATTERN count.checksChecking Counts for Elements-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking Counts for Elements</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:text[1]" priority="1000" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="/tei:TEI/tei:text[1]"/>

		    <!--REPORT Count-->
<xsl:if test="count(//tei:figure)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(//tei:figure)">
            <xsl:attribute name="id">r7</xsl:attribute>
            <xsl:attribute name="role">Count</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Total number of figures: <xsl:text/>
               <xsl:value-of select="count(//tei:figure)"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>

		    <!--REPORT Count-->
<xsl:if test="count(//tei:graphic)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(//tei:graphic)">
            <xsl:attribute name="id">r8</xsl:attribute>
            <xsl:attribute name="role">Count</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Total number of graphics: <xsl:text/>
               <xsl:value-of select="count(//tei:graphic)"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>

		    <!--REPORT Count-->
<xsl:if test="count(//tei:note[@type='abstract'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="count(//tei:note[@type='abstract'])">
            <xsl:attribute name="id">r15</xsl:attribute>
            <xsl:attribute name="role">Count</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Total number of abstracts: <xsl:text/>
               <xsl:value-of select="count(//tei:note[@type='abstract'])"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>

		    <!--REPORT Count-->
<xsl:if test="count(//tei:note[@type='endnote'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="count(//tei:note[@type='endnote'])">
            <xsl:attribute name="id">r9</xsl:attribute>
            <xsl:attribute name="role">Count</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Total number of endnotes: <xsl:text/>
               <xsl:value-of select="count(//tei:note[@type='endnote'])"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>

		    <!--REPORT Count-->
<xsl:if test="count(//tei:note[@type='footnote'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="count(//tei:note[@type='footnote'])">
            <xsl:attribute name="id">r10</xsl:attribute>
            <xsl:attribute name="role">Count</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Total number of footnotes: <xsl:text/>
               <xsl:value-of select="count(//tei:note[@type='footnote'])"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M30"/>
   <xsl:template match="@*|node()" priority="-2" mode="M30">
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>

   <!--PATTERN greek.checkCheck for Greek-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Check for Greek</svrl:text>

	  <!--RULE -->
<xsl:template match="*[text()[matches(.,'\p{IsGreek}')]]" priority="1000" mode="M31">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="*[text()[matches(.,'\p{IsGreek}')]]"/>

		    <!--REPORT Unicode-->
<xsl:if test="matches(.,'\p{IsGreek}')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(.,'\p{IsGreek}')">
            <xsl:attribute name="id">r11</xsl:attribute>
            <xsl:attribute name="role">Unicode</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Greek text should be compared with the print version to ensure accuracy: <xsl:text/>
               <xsl:value-of select="concat(substring(.,1,35),' . . .')"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M31"/>
   <xsl:template match="@*|node()" priority="-2" mode="M31">
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>

   <!--PATTERN greekextended.checkCheck for GreekExtended-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Check for GreekExtended</svrl:text>

	  <!--RULE -->
<xsl:template match="*[text()[matches(.,'\p{IsGreekExtended}')]]" priority="1000" mode="M32">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="*[text()[matches(.,'\p{IsGreekExtended}')]]"/>

		    <!--REPORT Unicode-->
<xsl:if test="matches(.,'\p{IsGreekExtended}')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                 test="matches(.,'\p{IsGreekExtended}')">
            <xsl:attribute name="id">r12</xsl:attribute>
            <xsl:attribute name="role">Unicode</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>GreekExtended text should be compared with the print version to ensure accuracy: <xsl:text/>
               <xsl:value-of select="concat(substring(.,1,35),' . . .')"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M32"/>
   <xsl:template match="@*|node()" priority="-2" mode="M32">
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>

   <!--PATTERN hebrew.checkCheck for Hebrew-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Check for Hebrew</svrl:text>

	  <!--RULE -->
<xsl:template match="*[text()[matches(.,'\p{IsHebrew}')]]" priority="1000" mode="M33">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="*[text()[matches(.,'\p{IsHebrew}')]]"/>

		    <!--REPORT Unicode-->
<xsl:if test="matches(.,'\p{IsHebrew}')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(.,'\p{IsHebrew}')">
            <xsl:attribute name="id">r13</xsl:attribute>
            <xsl:attribute name="role">Unicode</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Hebrew text should be compared with the print version to ensure accuracy: <xsl:text/>
               <xsl:value-of select="concat(substring(.,1,35),' . . .')"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M33"/>
   <xsl:template match="@*|node()" priority="-2" mode="M33">
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>

   <!--PATTERN graphic.checkCheck for Extant Graphics-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Check for Extant Graphics</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:graphic[@url]" priority="1000" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:graphic[@url]"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="lfn:file-exists(@url)=1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="lfn:file-exists(@url)=1">
               <xsl:attribute name="id">a13</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
				              <xsl:text/>
                  <xsl:value-of select="@url"/>
                  <xsl:text/> not found.
			</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M36"/>
   <xsl:template match="@*|node()" priority="-2" mode="M36">
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>

   <!--PATTERN graphic.Permissions.checkCheck for Permissions on Graphics-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Check for Permissions on Graphics</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:graphic" priority="1000" mode="M37">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:graphic"/>

		    <!--REPORT permissions-->
<xsl:if test="(@decls='#notCleared')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@decls='#notCleared')">
            <xsl:attribute name="id">r19</xsl:attribute>
            <xsl:attribute name="role">permissions</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
				Permissions not cleared for <xsl:text/>
               <xsl:value-of select="@url"/>
               <xsl:text/>
			         </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M37"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M37"/>
   <xsl:template match="@*|node()" priority="-2" mode="M37">
      <xsl:apply-templates select="*" mode="M37"/>
   </xsl:template>
   <xsl:param name="isbn_hyphen"
              select="concat(substring($isbn,1,3),'-',substring($isbn,4,1),'-',substring($isbn,5,4),'-',substring($isbn,9,4),'-',substring($isbn,13,1))"/>

   <!--PATTERN id_pub.checksChecking the ID against the header-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the ID against the header</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:idno[@type='ISBN']" priority="1000" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:idno[@type='ISBN']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="current()=$isbn"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="current()=$isbn">
               <xsl:attribute name="id">a22</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The ISBN in the header does not match the filename: <xsl:text/>
                  <xsl:value-of select="current()"/>
                  <xsl:text/> should be <xsl:text/>
                  <xsl:value-of select="$isbn"/>
                  <xsl:text/>
               </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M39"/>
   <xsl:template match="@*|node()" priority="-2" mode="M39">
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>

   <!--PATTERN id_pub.local.checksChecking the ID for proper type-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the ID for proper type</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:idno" priority="1000" mode="M40">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:idno"/>

		    <!--REPORT Priority1-->
<xsl:if test="@type='local'">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@type='local'">
            <xsl:attribute name="id">a522</xsl:attribute>
            <xsl:attribute name="role">Priority1</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>idno @type should be ISBN, not local.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M40"/>
   <xsl:template match="@*|node()" priority="-2" mode="M40">
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>

   <!--PATTERN target.checksChecking the ref target-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the ref target</svrl:text>

	  <!--RULE -->
<xsl:template match="tei:ref[@type='noteref']" priority="1000" mode="M41">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="tei:ref[@type='noteref']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="substring(@target,2)=//tei:note/@xml:id[.]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="substring(@target,2)=//tei:note/@xml:id[.]">
               <xsl:attribute name="id">a23</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All ref targets must point to existing note xml:ids. <xsl:text/>
                  <xsl:value-of select="substring(@target,2)"/>
                  <xsl:text/> does not exist.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M41"/>
   <xsl:template match="@*|node()" priority="-2" mode="M41">
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>

   <!--PATTERN pb-pageref.checksChecking the ref target-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the ref target</svrl:text>

	  <!--RULE -->
<xsl:template match="tei:ref[@type='pageref']" priority="1000" mode="M42">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="tei:ref[@type='pageref']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="substring(@target,2)=//tei:pb/@xml:id[.]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="substring(@target,2)=//tei:pb/@xml:id[.]">
               <xsl:attribute name="id">a21</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All pagerefs must point to existing pb xml:ids. <xsl:text/>
                  <xsl:value-of select="substring(@target,2)"/>
                  <xsl:text/> does not exist.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M42"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M42"/>
   <xsl:template match="@*|node()" priority="-2" mode="M42">
      <xsl:apply-templates select="*" mode="M42"/>
   </xsl:template>

   <!--PATTERN pageref.id.checksChecking the page ref target-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the page ref target</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:ref[@type='pageref']" priority="1000" mode="M43">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:ref[@type='pageref']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="substring-after(@target,'pg')=current()"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="substring-after(@target,'pg')=current()">
               <xsl:attribute name="id">a14</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All ref targets must match the actual page. <xsl:text/>
                  <xsl:value-of select="current()"/>
                  <xsl:text/> does not match <xsl:text/>
                  <xsl:value-of select="substring-after(@target,'pg')"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M43"/>
   <xsl:template match="@*|node()" priority="-2" mode="M43">
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <xsl:param name="chap-id" select="concat('uncp-',$isbn,'-c')"/>

   <!--PATTERN chapter.checksChecking the chapter Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the chapter Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:body/tei:div[@type='chapter']" priority="1000" mode="M45">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:body/tei:div[@type='chapter']"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="starts-with(@xml:id,'c')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(@xml:id,'c')">
               <xsl:attribute name="id">a15</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The id of chapter divs should have the following structure: c{chapNo}: <xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M45"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M45"/>
   <xsl:template match="@*|node()" priority="-2" mode="M45">
      <xsl:apply-templates select="*" mode="M45"/>
   </xsl:template>
   <xsl:param name="bib-id" select="concat('uncp-',$isbn,'-bibItem')"/>

   <!--PATTERN bibliography.checksChecking the bibliography Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the bibliography Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:div[@type='bibliography']//tei:bibl" priority="1000" mode="M47">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="//tei:div[@type='bibliography']//tei:bibl"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@xml:id)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@xml:id)">
               <xsl:attribute name="id">a16</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All bibliography items should have ids.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="starts-with(@xml:id,'bibItem')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(@xml:id,'bibItem')">
               <xsl:attribute name="id">a31</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>The id of bibItems should have the following structure: bibItem{No}: <xsl:text/>
                  <xsl:value-of select="@xml:id"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M47"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M47"/>
   <xsl:template match="@*|node()" priority="-2" mode="M47">
      <xsl:apply-templates select="*" mode="M47"/>
   </xsl:template>

   <!--PATTERN div.checksChecking the div Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the div Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:div" priority="1000" mode="M48">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:div"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="tei:head"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="tei:head">
               <xsl:attribute name="id">a117</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All divs generally have a head</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@type)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@type)">
               <xsl:attribute name="id">a118</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All divs must have a type or type attribute</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>

		    <!--REPORT Priority1-->
<xsl:if test="(@subtype)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@subtype)">
            <xsl:attribute name="id">r119</xsl:attribute>
            <xsl:attribute name="role">Priority1</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>Subhead sections should have a type attribute instead of subtype</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M48"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M48"/>
   <xsl:template match="@*|node()" priority="-2" mode="M48">
      <xsl:apply-templates select="*" mode="M48"/>
   </xsl:template>

   <!--PATTERN div_head.checksChecking the div head Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the div head Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:div[@type='ahead']" priority="1001" mode="M49">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:div[@type='ahead']"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="ancestor::tei:div[@type='chapter']|ancestor::tei:div[@type='introduction']|ancestor::tei:div[@type='preface']|ancestor::tei:div[@type='conclusion']|ancestor::tei:div[@type='endnotes']|ancestor::tei:div[@type='bibliography']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                                test="ancestor::tei:div[@type='chapter']|ancestor::tei:div[@type='introduction']|ancestor::tei:div[@type='preface']|ancestor::tei:div[@type='conclusion']|ancestor::tei:div[@type='endnotes']|ancestor::tei:div[@type='bibliography']">
               <xsl:attribute name="id">a19</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>ahead sections are generally children of chapters: this div has a type of <xsl:text/>
                  <xsl:value-of select="ancestor::tei:div/@type"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M49"/>
   </xsl:template>

	  <!--RULE -->
<xsl:template match="//tei:div[@type='bhead']" priority="1000" mode="M49">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:div[@type='bhead']"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="parent::tei:div[@type='ahead']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::tei:div[@type='ahead']">
               <xsl:attribute name="id">a20</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All bhead sections should be children of ahead divs: this div has a type of <xsl:text/>
                  <xsl:value-of select="parent::tei:div/@type"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M49"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M49"/>
   <xsl:template match="@*|node()" priority="-2" mode="M49">
      <xsl:apply-templates select="*" mode="M49"/>
   </xsl:template>

   <!--PATTERN bibl.checksChecking the bibl Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the bibl Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="/tei:TEI/tei:text/tei:back//tei:bibl" priority="1000" mode="M50">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context="/tei:TEI/tei:text/tei:back//tei:bibl"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="parent::tei:listBibl"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::tei:listBibl">
               <xsl:attribute name="id">a66</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All bibl elements in back should be children of listBibl:: this bibl's parent is <xsl:text/>
                  <xsl:value-of select="parent::tei:listBibl"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M50"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M50"/>
   <xsl:template match="@*|node()" priority="-2" mode="M50">
      <xsl:apply-templates select="*" mode="M50"/>
   </xsl:template>

   <!--PATTERN head.checksChecking the head Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the head Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:head" priority="1000" mode="M51">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:head"/>

		    <!--ASSERT Priority2-->
<xsl:choose>
         <xsl:when test="(@type)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@type)">
               <xsl:attribute name="id">a42</xsl:attribute>
               <xsl:attribute name="role">Priority2</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All heads generally have a type attribute</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M51"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M51"/>
   <xsl:template match="@*|node()" priority="-2" mode="M51">
      <xsl:apply-templates select="*" mode="M51"/>
   </xsl:template>

   <!--PATTERN bib.checksChecking the bibliography Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the bibliography Structure</svrl:text>

	  <!--RULE -->
<xsl:template match=" //tei:listBibl[@type='crossref']/tei:bibl//tei:title" priority="1000"
                 mode="M52">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                       context=" //tei:listBibl[@type='crossref']/tei:bibl//tei:title"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@level)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@level)">
               <xsl:attribute name="id">a43</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All bibl titles require a level attribute</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M52"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M52"/>
   <xsl:template match="@*|node()" priority="-2" mode="M52">
      <xsl:apply-templates select="*" mode="M52"/>
   </xsl:template>

   <!--PATTERN list-type.checksChecking the list Structure-->
<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl">Checking the list Structure</svrl:text>

	  <!--RULE -->
<xsl:template match="//tei:list" priority="1000" mode="M53">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//tei:list"/>

		    <!--ASSERT Priority1-->
<xsl:choose>
         <xsl:when test="(@type)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(@type)">
               <xsl:attribute name="id">a342</xsl:attribute>
               <xsl:attribute name="role">Priority1</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>All lists should have a type attribute</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M53"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M53"/>
   <xsl:template match="@*|node()" priority="-2" mode="M53">
      <xsl:apply-templates select="*" mode="M53"/>
   </xsl:template>
</xsl:stylesheet>