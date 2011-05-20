<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:tei="http://www.tei-c.org/ns/1.0"
      xmlns:cdla="http://cdla.unc.edu/ns"
      exclude-result-prefixes="xs tei cdla"
      extension-element-prefixes="cdla"
      version="2.0">
    
    <!-- bibliography.xsl: handles output for bibliographies, including embedding CoINs elements
        in the output. -->
    <xsl:function name="cdla:urlize-params">
        <xsl:param name="url-parameters"/>
        <xsl:for-each select="$url-parameters//param">
            <xsl:if test="position() > 1">
                <xsl:text>&amp;</xsl:text>
            </xsl:if>
            <xsl:value-of select="@name"/>
            <xsl:text>=</xsl:text>
            <xsl:value-of select="encode-for-uri(normalize-space(.))"/>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template name="make-book-coins">
        <parameters>
            <param name="rft_val_fmt">info:ofi/fmt:kev:mtx:book</param>
            <param name="rft.genre">book</param>
            <param name="rft.btitle"><xsl:value-of select="tei:title[@level='m']"/></param>
            <xsl:if test="tei:publisher">
                <param name="rft.pub"><xsl:value-of select="tei:publisher"/></param>
            </xsl:if>
            <xsl:if test="tei:pubPlace">
                <param name="rft.place"><xsl:value-of select="tei:pubPlace"/></param>
            </xsl:if>
            <xsl:for-each select="tei:author|tei:editor">
                <param name="rft.au"><xsl:value-of select="."/></param>
            </xsl:for-each>
            <xsl:if test="tei:date and number(tei:date[1]) > 0">
                <param name="date"><xsl:value-of select="tei:date"/></param>
            </xsl:if>
        </parameters>
    </xsl:template>
    
    <xsl:template name="make-journal-coins">
        <parameters>
            <param name="rft_val_fmt">info:ofi/fmt:kev:mtx:journal</param>
            <param name="rft.genre">article</param>
            <param name="rft.atitle">
                <xsl:value-of select="tei:title[@level='a']"/>
            </param>
            
            <param name="rft.jtitle">
                <xsl:choose>
                    <xsl:when test="tei:title[@level='j']">
                        <xsl:value-of select="tei:title[@level='j']"/>    
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="tei:title[not(@level)]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </param>
            <xsl:for-each select="tei:author|tei:editor">
                <param name="rft.au"><xsl:value-of select="."/></param>
            </xsl:for-each>
            <xsl:if test="tei:date">
                <param name="rft.date"><xsl:value-of select="tei:date"/></param>
            </xsl:if>
        </parameters>
        
    </xsl:template>
    
    <!-- This should be called with a tei:bibl node as the context item -->
    <xsl:template name="make-coins">
        <!-- not all bibl elements have titles; if so, we can't make coins out of them -->
        <xsl:if test="tei:title[@level='m']|tei:title[@level='a']">
            <xsl:variable name="coins-parameters">
                <xsl:choose>
                    <xsl:when test="tei:title[@level='m']">
                        <xsl:call-template name="make-book-coins"/>
                    </xsl:when>    
                    <xsl:otherwise>
                        <xsl:call-template name="make-journal-coins"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            &#160;<span xmlns="http://www.w3.org/1999/xhtml" class="Z3988">
                <xsl:attribute name="title">
                    <xsl:value-of select="cdla:urlize-params($coins-parameters)"/>
                </xsl:attribute>
            </span>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
