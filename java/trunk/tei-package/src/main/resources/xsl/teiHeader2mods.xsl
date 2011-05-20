<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:tei="http://www.tei-c.org/ns/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:mods="http://www.loc.gov/mods/v3"
      xmlns:cdla="http://cdla.unc.edu/ns"
      exclude-result-prefixes="xs xsi cdla"
      xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd"
      version="2.0"
      >
      
   	<!-- The only one of these used here is ISBN, and it's hard-coded -->
    <xsl:variable name="tei-print-identifiers">
    	<identifier>ISBN</identifier>
    	<identifier>ISBN-ALT</identifier>
    	<identifier>ISSN</identifier>
    </xsl:variable>
	
	<!-- Note that there might be ISBNs for electronic editions, but the data submitted typically has the ISBN
		for the *print edition* embedded in the fileDesc/publicationStmt section; thus this serves more as a 
		documentation of intent -->
	<xsl:variable name="tei-digital-identifiers">
		<identifier>DOI</identifier>
	</xsl:variable>

    <xsl:template match="tei:teiHeader" mode="tei2mods">
    	<xsl:variable name="header" select="."/>
    	<!-- The biblFull element for the print version -->
        <xsl:variable name="bibl" select="tei:fileDesc/tei:sourceDesc/tei:biblFull"/>
        <xsl:variable name="titleStmt" select="tei:fileDesc/tei:titleStmt"/>
    	<!-- the publicationStmt for the *digital file* -->
    	<xsl:variable name="digitalPubStmt" select="tei:fileDesc/tei:publicationStmt"/>
        <xsl:variable name="mainTitle">
        	<xsl:call-template name="findTitle">
        		<xsl:with-param name="titleStmt" select="$titleStmt"/>
        	</xsl:call-template>
        </xsl:variable>
        <xsl:variable name="subtitle" select="$titleStmt/tei:title[@type='sub']"/>
        <mods:mods version="3.3">
        	<mods:titleInfo>
                <mods:title><xsl:value-of select="normalize-space(if ($titleStmt/tei:title[@type='main']) then $titleStmt/tei:title[@type='main'] else $titleStmt/tei:title[1])"/></mods:title>
                <xsl:if test="$subtitle">
                    <mods:subTitle><xsl:value-of select="normalize-space($subtitle)"/></mods:subTitle>
                </xsl:if>
            </mods:titleInfo>
		<xsl:for-each select="$titleStmt/(tei:author|tei:editor)">
			<xsl:call-template name="author-info">
				<xsl:with-param name="authorElement">
					<xsl:call-template name="find-author"/>
				</xsl:with-param>					
			</xsl:call-template>
		</xsl:for-each>
		<mods:typeOfResource>text</mods:typeOfResource>
        <xsl:variable name="genreElement" select=".//tei:textClass/tei:classCode[@scheme='http://purl.org/eprint/type' or @scheme='http://lcrm.lib.unc.edu/genre'][1]"/>
        <xsl:if test="$genreElement">
        	<mods:genre><xsl:value-of select="$genreElement"/></mods:genre>
        </xsl:if>	
        <xsl:if test="$bibl/tei:extent">
        	<mods:extent><xsl:value-of select="$bibl/tei:extent"/></mods:extent>
        </xsl:if>
		<xsl:call-template name="publication-info">
			<xsl:with-param name="bibl" select="$bibl"/>
			<xsl:with-param name="digPubStmt" select="$digitalPubStmt"/>
		</xsl:call-template> 
		<xsl:variable name="abstractText" select="$bibl/tei:notesStmt/tei:note[@type='abstract']/tei:p"/>
		<mods:abstract>
			<xsl:choose>
				<xsl:when test="$abstractText">
					<xsl:value-of select="normalize-space($abstractText)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>No abstract is available for this document.</xsl:text>
				</xsl:otherwise>
				</xsl:choose>
			</mods:abstract>
		<xsl:for-each select="tei:profileDesc/tei:textClass/tei:keywords[@scheme='LCSH']/tei:list/tei:item">
		<mods:subject authority="lcsh">
			<mods:topic><xsl:value-of select="."/></mods:topic>
		</mods:subject>
		</xsl:for-each>
        </mods:mods>
    </xsl:template>
    
    <xsl:template name="findTitle">
    	<xsl:param name="titleStmt" as="element()" required="yes"/>
    	<xsl:choose>
    		<xsl:when test="$titleStmt/tei:title[@type='main']">
    			<xsl:value-of select="normalize-space($titleStmt/tei:title[@type='main'])"/>
    		</xsl:when>
    		<xsl:when test="count($titleStmt/tei:title) = 1">
    			<xsl:value-of select="normalize-space($titleStmt/tei:title[1])"/>
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:message terminate="yes">
    				In tei:titleStmt there is more than one title element but none has @type='main'
    			</xsl:message>
    		</xsl:otherwise>
    	</xsl:choose>
    </xsl:template>
    
    <xsl:template name="find-author" as="element()">
    <!--  Postelization: if a ptr element is present, its @target attribute may
    	  be an HTML style fragment ID or an outright idref; accept both -->
    	<xsl:choose>
			<xsl:when test="tei:ptr">
				<xsl:variable name="idref">
				<xsl:choose>
					<xsl:when test="starts-with(tei:ptr/@target, '#')">
						<xsl:value-of select="substring-after(tei:ptr/@target, '#')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="tei:ptr/@target"/>
					</xsl:otherwise>
				</xsl:choose>
				</xsl:variable>
				<xsl:copy-of select="//*[@xml:id=$idref]"/>
			</xsl:when>
			<!--  absence of a ptr element indicates this is the 'canonical' source -->
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
    </xsl:template>
    
    <xsl:template name="publication-info">
    	<xsl:param name="bibl" required="yes"/>
    	<xsl:param name="digPubStmt" required="yes"/>
    	<xsl:variable name="pubstmt" select="$bibl/tei:publicationStmt"/>
		<mods:originInfo>
			<mods:publisher><xsl:value-of select="$pubstmt/tei:publisher"/></mods:publisher>
			<mods:place>
				<mods:placeTerm type="text"><xsl:value-of select="$pubstmt/tei:pubPlace"/></mods:placeTerm>
			</mods:place>
			<xsl:variable name="pubDate" select="$pubstmt/tei:date"/>
			<xsl:if test="$pubDate">
				<mods:dateIssued keyDate="yes" encoding="w3cdtf"><xsl:value-of select="$pubDate"/></mods:dateIssued>
			</xsl:if>				
		</mods:originInfo>
		<xsl:if test="$pubstmt//tei:idno[@type='ISBN']">
		<mods:identifier type="isbn"><xsl:value-of select="$pubstmt//tei:idno[@type='ISBN']"/></mods:identifier>
		</xsl:if>
    	<xsl:if test="$digPubStmt/tei:idno[@type='DOI']">
    			<mods:identifier type="doi"><xsl:value-of select="$digPubStmt/tei:idno[@type='DOI']"/></mods:identifier>
  		</xsl:if>
    </xsl:template>
    
    <xsl:template name="author-info">
    	<xsl:param name="authorElement" as="document-node()" required="yes"/>
    	<xsl:variable name="ctx" select="$authorElement/(tei:author|tei:editor)"/> 
    	<mods:name type="personal">
    		<xsl:if test="$ctx[@xml:id]">
    			<xsl:attribute name="xml:id" select="$ctx/@xml:id"/>
    		</xsl:if>
    		<xsl:call-template name="create-role-element">
    			<xsl:with-param name="elementName" select="local-name($authorElement/*[1])"/>
    		</xsl:call-template>
    		<!--
			<mods:role>
				<mods:roleTerm type="code" authority="marcrelator">aut</mods:roleTerm>
				<mods:roleTerm type="text" authority="marcrelator">Author</mods:roleTerm>
			</mods:role>
			-->
			<xsl:if test="$ctx/tei:reg">
				<mods:namePart><xsl:value-of select="$ctx/tei:reg"/></mods:namePart>
			</xsl:if>
    		<xsl:if test="$ctx/tei:name/tei:forename">
    			<xsl:variable name="foreNames" select="$ctx/tei:name/tei:forename"/>
    			<xsl:variable name="givenName" select="if ($foreNames[@type='given']) then $foreNames[@type='given'][1] else $foreNames[not(@type)][1]"/>
    			<mods:namePart type="given"><xsl:value-of select="$givenName"/></mods:namePart>
    		</xsl:if>
    		<xsl:if test="$ctx/tei:name/tei:surname">
    			<mods:namePart type="family"><xsl:value-of select="$ctx/tei:name/tei:surname"/></mods:namePart>
    		</xsl:if>
			<mods:displayForm><xsl:value-of select="normalize-space($ctx/tei:name)"/></mods:displayForm>
		</mods:name>
    </xsl:template>
	
	<xsl:template name="create-role-element">
		<xsl:param name="elementName"/>
		<xsl:variable name="code" select="if ($elementName = 'author') then 'aut' else 'edt'"/>
		<xsl:variable name="text" select="if ($elementName = 'author') then 'Author' else 'Editor'"/>
		<mods:role>
			<mods:roleTerm type="code" authority="marcrelator"><xsl:value-of select="$code"/></mods:roleTerm>
			<mods:roleTerm type="text" authority="marcrelator"><xsl:value-of select="$text"/></mods:roleTerm>
		</mods:role>
	</xsl:template>
	
	<xsl:template match="tei:forename|tei:surname"/>
</xsl:stylesheet>
