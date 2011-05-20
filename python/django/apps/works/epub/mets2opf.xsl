<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mets="http://www.loc.gov/METS/"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns="http://www.idpf.org/2007/opf"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="mets mods tei xlink"
    version="1.0">
    
    <xsl:output indent="yes" encoding="utf-8"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="mets:mets"/>
    </xsl:template>
    
    
    
    <xsl:template match="mets:mets">
        <package version="2.0" unique-identifier="BookId">
            <xsl:apply-templates select="mets:dmdSec[@ID='bibliographic-record']//mods:mods"/>
            <xsl:variable name="htmlFiles" select="//mets:fileGrp[@ID='html-sections']/mets:file[@MIMETYPE='application/xhtml+xml']"/>
            <xsl:variable name="mediaFiles" select="//mets:fileGrp[@ID='media']/mets:file"/>
            
        <manifest>
                <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
                <xsl:for-each select="$htmlFiles|$mediaFiles">
                   <item id="{@ID}" href="{ mets:FLocat/@xlink:href }" media-type="{ @MIMETYPE }"/> 
                </xsl:for-each>
        </manifest>
            <spine toc="ncx">
                <xsl:for-each select="$htmlFiles">
                    <itemref idref="{@ID}"/>
                </xsl:for-each>
            </spine>
        </package>
        
    </xsl:template>
    
    <xsl:template match="mods:mods">
        <xsl:variable name="creator" select="mods:name[@type='personal']"></xsl:variable>
        <metadata>
        <dc:title><xsl:value-of select="mods:titleInfo/mods:title/text()"/></dc:title>
        <dc:language>en</dc:language>
        <dc:identifier id="BookId" opf:scheme="ISBN"><xsl:value-of select="mods:identifier[@type='isbn']/text()"/></dc:identifier>
        <dc:creator opf:file-as="{ $creator[1]/mods:namePart[not(@type)]/text() }"><xsl:value-of select="$creator[1]/mods:displayForm"/></dc:creator>
        </metadata>
    </xsl:template>
</xsl:stylesheet>
