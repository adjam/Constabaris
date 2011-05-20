<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:cdla="http://cdla.unc.edu/xslt"
    extension-element-prefixes="cdla"
    exclude-result-prefixes="tei cdla xs"
    version="2.0">
    
    <!-- 
        driver.xsl : this is the main driver stylesheet that transforms a single TEI P5 input document
        into (possibly) multiple output XHTML documents.
    -->
    
    <xsl:import href="core.xsl"/>
    
    <xsl:import href="make-chunkmap.xsl"/>

    <xsl:output encoding="utf-8"
                omit-xml-declaration="yes"
                indent='yes'/>

    <xsl:param name="outputDirectory">output</xsl:param>

    <!-- first, 'chunk' the TEI into multiple output units -->
    <xsl:variable name="chunks" select="cdla:chooseChunks($textElement)"/>
    
    <!-- create the chunk map; this will be used to resolve inter-chunk references to the right
        output units; e.g. if the book has endnotes, this will ensure that a footnote marker in chapter 1 points to 
        the file containing the endnotes. The chunk map is also the primary output of the stylesheet -->
    <xsl:variable name="chunk-map">
        <xsl:call-template name="create-chunkmap">
            <xsl:with-param name="chunk-style" select="$chunkStyle"/>
            <xsl:with-param name="chunks" select="$chunks"/>
        </xsl:call-template>
    </xsl:variable>
    

    <xsl:template match="/">
        <!-- This is the output -->
        <xsl:copy-of select="$chunk-map"/>
        
        <xsl:for-each select="$chunks">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="chunk-info" select="$chunk-map//chunk[$pos]" as="element()"/>
            <xsl:apply-templates select=".">
                <xsl:with-param name="chunk-map" select="$chunk-map" as="document-node()" tunnel="yes"/>
                <xsl:with-param name="chunk-info" select="$chunk-info" as="element()" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="tei:front">
        <xsl:call-template name="emit-chunk">
            <xsl:with-param name="chunk-type">frontmatter</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:back/tei:div">
        <xsl:call-template name="emit-chunk">
            <xsl:with-param name="chunk-type">backmatter</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:body/tei:div">
        <xsl:call-template name="emit-chunk">
                <xsl:with-param name="chunk-type">body</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- For purposes of this stylesheet, we don't want to output any of the header information;
         see teiHeader2mods.xsl -->
    <xsl:template match="tei:teiHeader"/>

    <xsl:template match="tei:div[@type='endnotes']//tei:note">
        <div class="note">
            <div class="noteref">
                <xsl:attribute name="id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
                <a>
                    <xsl:attribute name="href">
                        <xsl:call-template name="reverse-internal-reference">
                            <xsl:with-param name="element-id" select="@xml:id"/>
                        </xsl:call-template>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="tei:num">
                            <xsl:value-of select="tei:num"/>
                        </xsl:when>
                        <xsl:when test="@n">
                            <xsl:value-of select="@n"/>
                        </xsl:when>
                        <xsl:otherwise>note</xsl:otherwise>
                    </xsl:choose>
                </a>
            </div>
            <div class="notebody">
                <xsl:apply-templates/>
            </div>
            <div class="clearblock">&#160;</div>
        </div>
    </xsl:template>
    
   
        
    <!-- 
        Finds the filename of the chunk that contains a reference to the supplied id;
        e.g. while processing an endnote, finds the filename of the chunk containing the
        reference to this note.
        This template overrides a much simpler one in core.xsl 
    -->
    <xsl:template name="reverse-internal-reference">
        <xsl:param name="element-id"/>
        <xsl:variable name="targetValue" select="concat('#', $element-id)"/>
        <xsl:variable name="ref-element" select="/tei:TEI/tei:text//tei:ref[@target=$targetValue]"/>
        <xsl:if test="$DEBUG">
            <xsl:choose>
                <xsl:when test="$ref-element">
                    <xsl:message>Found <xsl:value-of select="name($ref-element)"/> with target
                            <xsl:value-of select="$element-id"/></xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Nothing that points to <xsl:value-of select="$element-id"/>
                        found</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:variable name="reference-id">
            <xsl:call-template name="backreference-id">
                <xsl:with-param name="reference-id" select="$element-id"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$chunk-map//ref[@target-id=$element-id]/../@filename"/>
        <xsl:text>#</xsl:text>
        <xsl:value-of select="$reference-id"/>
    </xsl:template>
    
    
    <!-- Find the filename of the chunk containing the ID to which a reference points; this is useful for, e.g. endnotes and page numbers in book indexes
        so users will be able to quickly navigate back to the point in the text where they are referenced.
    This template overrides a much simpler one in core.xsl
    -->
    <xsl:template name="resolve-internal-reference">
        <xsl:param name="targetId"/>
        <xsl:variable name="target" select="$chunk-map//*[@xml:id=$targetId]"/>
        <xsl:variable name="reference-filename">
            <xsl:value-of select="$target/ancestor-or-self::chunk[1]/@filename"/>
            <!--
            <xsl:choose>
                <xsl:when test="name($target) = 'chunk'">
                    <xsl:value-of select="$target/@filename"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$target/ancestor::chunk/@filename"/>
                </xsl:otherwise>
            </xsl:choose>
            -->
        </xsl:variable>
        <xsl:value-of select="concat($reference-filename,'#', $targetId)"/>
    </xsl:template>
</xsl:stylesheet>
