<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mets="http://www.loc.gov/METS/"
    xmlns:mods="http://www.loc.gov/mods/v3"
    
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns="http://www.daisy.org/z3986/2005/ncx/"
    exclude-result-prefixes="mets mods tei xlink"
    version="1.0">
    
    <xsl:output encoding="utf-8" 
                indent="yes"
                doctype-public="-//NISO//DTD ncx 2005-1//EN"
                doctype-system="http://www.daisy.org/z3986/2005/ncx-2005-1.dtd"/>
        
    <xsl:template match="/">
        <xsl:variable name="htmlFiles" select="//mets:fileGrp[@ID='html-sections']/mets:file[@MIMETYPE='application/xhtml+xml']"/>
        <ncx version="2005-1" xml:lang="en">
            <head>
                <meta name="dtb:uid" content="{ //mods:mods/mods:identifier[@type='isbn'] }"/>
                <meta name="dtb:depth" content="1"/> <!-- 1 or higher -->
                <meta name="dtb:totalPageCount" content="0"/> <!-- must be 0 -->
                <meta name="dtb:maxPageNumber" content="0"/>
            </head>
            
            <xsl:apply-templates select="//mets:dmdSec[@ID='bibliographic-record']//mods:mods"/>
            
            <navMap>
                <xsl:for-each select="$htmlFiles">
                    <xsl:variable name="fileId" select="@ID"/>
                    <navPoint class="chapter" id="{ $fileId }" playOrder="{ position() }">
                        <navLabel><text><xsl:value-of select="//mets:fptr[@FILEID=$fileId]/../@LABEL"/></text></navLabel>
                        <content src="{ mets:FLocat/@xlink:href }"/>
                    </navPoint>
                </xsl:for-each>
            </navMap>
           
        </ncx>
    </xsl:template>
    
    
    <xsl:template match="mods:mods">
        
        <xsl:variable name="marcRoles" select="//mods:mods/mods:name[mods:role/mods:roleTerm[@authority='marcrelator' and (text() = 'aut' or text() = 'edt')]]"/>
        <docTitle>
            <text><xsl:value-of select="mods:titleInfo/mods:title"/></text>
        </docTitle>
        
        <xsl:for-each select="$marcRoles">
        <docAuthor>
            <text><xsl:value-of select="mods:namePart[not(@type)]"/></text>
        </docAuthor>
        </xsl:for-each>
        
        
        
    </xsl:template>

</xsl:stylesheet>
