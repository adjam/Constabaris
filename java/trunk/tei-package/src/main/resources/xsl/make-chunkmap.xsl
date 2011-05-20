<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:cdla="http://cdla.unc.edu/xslt"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="tei cdla xs"
    version="2.0">
    
    <xsl:import href="chunker.xsl"/>
    
    <xsl:key name="ids" match="//*[@xml:id]" use="@xml:id"/>
    
    <xsl:key name="targets" match="//*[@target]" use="@target"/>
 
    <xsl:template name="create-chunkmap">
        <xsl:param name="chunks"/>
        <xsl:param name="chunk-style"/>
    
        <chunks style="{$chunk-style}">
            <xsl:for-each select="$chunks">
            <chunk>
                <xsl:choose>
                   <xsl:when test="@xml:id">
                   <xsl:attribute name="source-id">
                       <xsl:value-of select="@xml:id"/>
                   </xsl:attribute>
                    <xsl:attribute name="xml:id" select="@xml:id"/>
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:attribute name="source-path">
                           <xsl:apply-templates select="." mode="find-path"/>    
                       </xsl:attribute>
                   </xsl:otherwise>
                 </xsl:choose>
               <xsl:attribute name="filename">
                   <xsl:call-template name="get-chunk-filename"/>
               </xsl:attribute>
               <xsl:attribute name="title">
                   <xsl:call-template name="get-section-title"/>
               </xsl:attribute>
               <xsl:call-template name="locate-page-boundaries"/>
               <xsl:apply-templates select=".//*[@target]" mode="find-references"/>
               <!-- <xsl:apply-templates select=".//tei:ref[@type='noteref']" mode="chunkmap"/> -->
               <xsl:apply-templates select=".//*[@xml:id]" mode="find-ids"/>
           </chunk>
       </xsl:for-each>
        </chunks>
    </xsl:template>
    
    <xsl:template match="tei:ref[@type='noteref']" mode="chunkmap">
        <xsl:variable name="refid" select="if (@xml:id) then @xml:id else generate-id(.)"/>
        <target xml:id="{$refid}" target-id="{@target}"/>
    </xsl:template>
    
    <xsl:template match="*[@xml:id]" mode="find-ids">
        <target xml:id="{@xml:id}" source-type="{ name(.) }"/>
    </xsl:template>
    
    <xsl:template match="tei:ref/text()" mode="find-references"/>
    
    
    <!-- Elements with "target" attributes that start with a 'hash' are internal
        pointers -->
    <xsl:template match="*[@target and starts-with(@target, '#')]" mode="find-references">
            <xsl:variable name="target-id" select="substring(@target,2)"/>
        <!--
            <xsl:if test="not(id($target-id))">
                <xsl:message terminate="yes">ID '<xsl:value-of select="$target-id"/>' not found</xsl:message>
            </xsl:if>
            -->
            <ref target-id="{$target-id}">
                    <xsl:attribute name="xml:id" select="if (@xml:id) then @xml:id else generate-id(.)"/>
            </ref>
    </xsl:template>
    
    <xsl:template name="locate-page-boundaries">
        <xsl:variable name="pagebreaks" select=".//tei:pb"/>
        <xsl:if test="$pagebreaks">
            <xsl:variable name="firstpage" select="$pagebreaks[1]/@n"/>
            <xsl:variable name="lastpage" select="$pagebreaks[last()]/@n"/>
            <xsl:if test="string-length($firstpage) &gt; 0">
                <xsl:attribute name="first-page">
                    <xsl:value-of select="$firstpage"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="string-length($lastpage) &gt; 0">
                <xsl:attribute name="last-page">
                    <xsl:value-of select="$lastpage"/>
                </xsl:attribute>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
