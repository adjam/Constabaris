<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:cdla="http://cdla.unc.edu/xslt"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="cdla xs tei"
    xmlns="http://www.w3.org/1999/xhtml"
    version="2.0">



    <!-- chunker.xsl: this stylesheet is responsible for outputting the correct 'chunks' of the document.
      -->
         
    <xsl:param name="DEBUG" select="false()"/>
    
    <xsl:variable name="chunkPI" select="normalize-space(string(/processing-instruction('uncp-output-style')))"/>
    
    <xsl:variable name="chunkStyle">
        <xsl:choose>
            <xsl:when test="$chunkPI = 'body' or $chunkPI = onepage">
                <xsl:text>body</xsl:text>
            </xsl:when>
            <xsl:when test="$chunkPI = 'all' or $chunkPI = 'chapters'">
                <xsl:text>all</xsl:text>
            </xsl:when>
            <xsl:when test="$chunkPI = 'partschapters'">
                <xsl:text>partschapters</xsl:text>                
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>all</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:param name="outputDirectory">output</xsl:param>
        
    <xsl:variable name="textElement" select="/tei:TEI/tei:text"/>
    
    <!-- We need to use this custom function because there's no way to use <xsl:choose>
    to return this or that or the other value when the value must be a node set -->
    
    <xsl:function name="cdla:chooseChunks">
        <xsl:param name="textElement"/>
        <xsl:if test="$DEBUG">
            <xsl:message>Chunk Style: '<xsl:value-of select="$chunkStyle"/>'</xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$chunkStyle = 'all'">
                <!-- chapters => front / top-level divs in body, top-level divs in back -->
                <xsl:sequence select="$textElement/tei:front|$textElement/tei:body/tei:div|$textElement/tei:back/tei:div"/>
            </xsl:when>
            <xsl:when test="$chunkStyle = 'body'">
                <!-- no front or backmatter; it's expected that *usually* there is one top level div in the body -->
                <xsl:sequence select="$textElement/tei:body/tei:div"/>
            </xsl:when>
            <xsl:when test="$chunkStyle = 'partschapters'">
                <!-- parts chapters : like chapters except chapters in body are top-level children of div@type='part';
                    parts get ignored with respect to chunk structure, as will any non-div children of top-level part divs. -->
                <xsl:sequence select="$textElement/tei:front|$textElement/tei:body/tei:div[@type='part']/tei:div|$textElement/tei:back/tei:div"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">Chunk style '<xsl:value-of select="$chunkStyle"/>' not
                    recognized</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template name="get-chunk-filename">
        <xsl:param name="position" select="position()"/>
        <xsl:number format="001" value="$position"/>
        <xsl:text>-segment.html</xsl:text>
    </xsl:template>
    
    <xsl:template name="get-chunk-id">
        <xsl:choose>
            <xsl:when test="@xml:id">
                <xsl:value-of select="@xml:id"/>
            </xsl:when>
            <xsl:when test="name() = 'front'">
                <xsl:text>frontmatter</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="generate-id(.)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    
    
    <!-- Calling this template on a given node will generate an 
        XPath that (uniquely) points to the node; note that the names output will completely
        omit the namespace prefix! -->
    <xsl:template match="*" mode="find-path">
        <xsl:text>/</xsl:text>
        <xsl:for-each select="ancestor-or-self::*">
            <xsl:variable name="name" select="node-name(.) cast as xs:string"/>
            <xsl:variable name="previous-siblings" select="count(preceding-sibling::*[name() = $name])"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$name"/>
            <xsl:if test="$previous-siblings &gt; 0 or following-sibling::*[name() = $name]">
                <xsl:text>[</xsl:text>
                <xsl:value-of select="$previous-siblings+1"/>
                <xsl:text>]</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    

    <xsl:template name="get-section-title">
        <xsl:choose>
            <xsl:when test="tei:head">
                <xsl:choose>
                    <xsl:when test="tei:head[@type='chapterTitle']">
                        <xsl:value-of select="normalize-space(tei:head[@type='chapterTitle'])"/> 
                    </xsl:when>                
                    <xsl:when test="tei:head[@type='main']">
                        <xsl:value-of select="normalize-space(tei:head[@type='main'])"/> 
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(tei:head[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="name(.) = 'front'">
                <xsl:text>Front Matter</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('Untitled', '(', name(.), ')')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="emit-chunk">
        <xsl:param name="chunk-position" tunnel="yes"/>
        <xsl:param name="chunk-info" as="element()" tunnel="yes"/>
        <xsl:param name="chunk-type"/>
        <xsl:variable name="filename" select="data($chunk-info/@filename)" as="xs:string"/>
        
        <xsl:variable name="output-file" select="concat($outputDirectory, '/', $filename)"/>
        <xsl:result-document href="{$output-file}" media-type="application/xhtml+xml" encoding="utf-8"
            indent="yes">
            <xsl:call-template name="emit-chunk-div">
                <xsl:with-param name="chunk-type" select="$chunk-type"/>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="emit-chunk-div">
        <xsl:param name="chunk-type"/>
        <div class="{$chunk-type}" id="{ if (@xml:id) then @xml:id else generate-id(.) }">
            
            <xsl:call-template name="sibling-elements"/>
            <xsl:apply-templates/>
            <xsl:if test=".//tei:note[@type='footnote']">
                <div class="footnotes">
                    <xsl:apply-templates select=".//tei:note[@type='footnote']" mode="footnotes"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
        
    
    <!-- this template finds elements that are siblings of the current chunk but are not themselves in a chunk, and applies the templates that apply to them
        so the output is contained within the current chunk; this allows for introductory material in an article to appear in the HTML of the first chunk,
        for example -->
    <xsl:template name="sibling-elements">
        <xsl:variable name="previous-div" select="preceding-sibling::tei:div[1]"/>
        <xsl:variable name="prev-outsiders" select="if ($previous-div) then preceding-sibling::*[not(local-name(.) = 'div')] intersect $previous-div/following-sibling::*[not(local-name(.) = 'div')] else  preceding-sibling::*[not(local-name(.) = 'div')]"/>
        <xsl:if test="$DEBUG">
            <xsl:message>Previous non-div siblings of current chunk: <xsl:value-of select="count($prev-outsiders)"/></xsl:message>
        </xsl:if>
        <xsl:apply-templates select="$prev-outsiders"/>
    </xsl:template>
    
    <xsl:template name="emit-page-chunk">
        <xsl:param name="chunk-info"/>
        <xsl:param name="chunktype">body</xsl:param>
        <xsl:variable name="outputFile" select="concat($outputDirectory,'/', $chunk-info/@filename)"/>
        <xsl:result-document href="{$outputFile}" media-type="application/xhtml+xml" encoding="utf-8">
                    <html xmlns="http://www.w3.org/1999/xhtml">
                        <head>
                            <title><xsl:value-of select="$chunk-info/@title"/></title>
                            <link rel="stylesheet" href="styles.css" type="text/css"/>
                        </head>
                        <body>
                            <div class="{$chunktype}">
                                <xsl:apply-templates/>
                            </div>
                        </body>
                    </html>
        </xsl:result-document>
    </xsl:template>
    
    
    
    

</xsl:stylesheet>
