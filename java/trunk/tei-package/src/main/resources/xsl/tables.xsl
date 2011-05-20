<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:lcrm="https://lcrm.lib.unc.edu/ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="tei lcrm xs"
    version="2.0">
    
   <!-- Stylesheet for handling of tables -->  
    
    <xsl:function name="lcrm:count-columns">
        <xsl:param name="table" as="element()"/>
        <xsl:variable name="colspans" as="xs:integer*">
            <xsl:for-each select="$table/tei:row[1]/tei:cell">
                    <xsl:value-of select="if (@cols) then number(@cols) else 1"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="sum($colspans)"/>
    </xsl:function>
    
    <xsl:template match="tei:head" mode="table-caption">
        <caption>
            <xsl:apply-templates/>
        </caption>
    </xsl:template>
    
    <xsl:template match="tei:table">
        <xsl:variable name="columnCount" select="lcrm:count-columns(.)"/>
        <table>
            <xsl:attribute name="id">
                <xsl:value-of select="if (@xml:id) then @xml:id else generate-id(.)"/>
            </xsl:attribute>
            <xsl:if test="@type">
                <xsl:attribute name="class" select="@type"/>
            </xsl:if>
            <xsl:apply-templates select="tei:head" mode="table-caption"/>
            <xsl:for-each select="tei:row">
                <tr>
                    <xsl:for-each select="tei:cell">
                        <xsl:variable name="element-name" select="if ( @role = 'label' ) then 'th' else 'td'"/>
                        <xsl:element name="{$element-name}">
                            <xsl:call-template name="row-col-atts"/>
                            <xsl:call-template name="cell-contents"/>
                        </xsl:element>
                    </xsl:for-each>
                </tr>
            </xsl:for-each>
        <xsl:if test="tei:note">
                <xsl:for-each select="tei:note">
                    <xsl:variable name="targetHref">
                        <xsl:call-template name="backreference-id">
                            <xsl:with-param name="reference-id" select="@xml:id"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <tr class="table-note">
                        <td colspan="{ $columnCount }">
                            <xsl:if test="not(@type='source')">
                            <a href="#{$targetHref}" id="{if (@xml:id) then @xml:id else generate-id(.)}">
                                <xsl:choose>
                                    <xsl:when test="@n">
                                        <xsl:value-of select="@n"/>
                                    </xsl:when>
                                    <xsl:when test="tei:num">
                                        <xsl:value-of select="tei:num"/>
                                    </xsl:when>
                                    <xsl:when test="text()[normalize-space(.)]|*">
                                        <xsl:apply-templates/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>note</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </a>
                            &#160;
                            </xsl:if>
                            <xsl:apply-templates />
                        </td>
                    </tr>
                </xsl:for-each>
           
        </xsl:if>
        </table>
    </xsl:template>
    
    
    <xsl:template name="cell-contents">
        <xsl:variable name="contents" select="normalize-space(.)"/>
        <xsl:choose>
            <xsl:when test="$contents">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                &#x200b;
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="row-col-atts">
        <xsl:if test="@cols">
            <xsl:attribute name="colspan">
                <xsl:value-of select="@cols"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@rows">
            <xsl:attribute name="rowspan">
                <xsl:value-of select="@rows"/>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
