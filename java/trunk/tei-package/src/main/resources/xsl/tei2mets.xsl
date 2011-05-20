<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.loc.gov/METS/"
    xmlns:cdla="http://cdla.unc.edu/xslt"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="cdla"
    version="2.0">
    
    <xsl:import href="chunker.xsl"/>
    
    <xsl:import href="teiHeader2mods.xsl"/>
    
    <xsl:output indent="yes" encoding="utf-8"/>
    <!-- 
    <xsl:variable name="chunkPI" select="normalize-space(string(/processing-instruction('uncp-output-style')))"/>
    
    <xsl:param name="chunkType" select="if ( $chunkPI = 'onepage' ) then 'onepage' else 'chapters'"/>
    -->
    
    <xsl:param name="dmdid">bibliographic-record</xsl:param>
    
    <xsl:variable name="chunks" select="cdla:chooseChunks(/tei:TEI/tei:text)"/>   
    
    <xsl:variable name="lastPagebreaks" select="$chunks//tei:pb[last()]"/>
    
    <xsl:template match="/">
        <mets>
            <xsl:call-template name="dmd-sec">
                <xsl:with-param name="header" select="/tei:TEI/tei:teiHeader"/>
            </xsl:call-template>
            <fileSec ID="content-files">
                <xsl:call-template name="file-sec"/>
            </fileSec>
            <xsl:call-template name="struct-map"/>
        </mets>
    </xsl:template>
    
    <xsl:template name="dmd-sec">
        <xsl:param name="header"/>
        
        <dmdSec ID="{$dmdid}">
            <mdWrap MDTYPE="MODS">
                <xmlData>
                    <xsl:apply-templates mode="tei2mods" select="tei:TEI/tei:teiHeader"/>
                </xmlData>
            </mdWrap>
        </dmdSec>
    </xsl:template>
    
    <xsl:template name="file-sec">
        <fileGrp ID="sources">
            <file ID="source" MIMETYPE="application/xml" DMDID="{$dmdid}">
                <FLocat ID="source-location" LOCTYPE="URL" xlink:href="tei.xml"/>
            </file>
        </fileGrp>
        <xsl:call-template name="cover-art"/>
        <xsl:call-template name="document-sections"/>
        <xsl:call-template name="linked-media"/>
    </xsl:template>
    
    <xsl:template name="linked-media">
        <xsl:variable name="figures" select="//tei:figure"/>
        <xsl:if test="$figures">
            <fileGrp ID="media">
                <xsl:for-each select="$figures">
                    <file ID="figure-file-{ @xml:id }" MIMETYPE="{ cdla:fileMimeType(tei:graphic/@url) }">
                        <FLocat LOCTYPE="URL" xlink:href="content/{tei:graphic/@url}"/>
                    </file>
                </xsl:for-each>
            </fileGrp>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="cdla:fileMimeType">
        <xsl:param name="filename"/>
        <xsl:analyze-string select="normalize-space(lower-case($filename))"
            regex="^.*\.(jpg|jpeg|png|gif|jp2)$">
            <xsl:matching-substring>
                <xsl:variable name="ext" select="regex-group(1)"/>
                <xsl:choose>
                    <xsl:when test="$ext = 'jpg' or $ext = 'jpeg'">
                        <xsl:text>image/jpeg</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext='png'">
                        <xsl:text>image/png</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'gif'">
                        <xsl:text>image/gif</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'jp2'">
                        <xsl:text>image/jp2</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Unrecognized image extension '<xsl:value-of select="$ext"/>'</xsl:message>
                        <xsl:text>application/octet-stream</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:matching-substring>
         
            <xsl:non-matching-substring>
                <xsl:message>Unable to determine file type for URL '<xsl:value-of select="$filename"/>'</xsl:message>
                <xsl:text>application/octet-stream</xsl:text>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:template name="cover-art">
        <xsl:variable name="has-cover" select="unparsed-text-available('cover.jpg')"/>
        <xsl:variable name="has-back-cover" select="unparsed-text-available('back-cover.jpg')"/>
        <xsl:if test="$has-cover or $has-back-cover">
            <fileGrp ID="cover-art-group">
                <xsl:if test="$has-cover">
                    <file ID="cover-art" MIMETYPE="image/jpg" LABEL="Front Cover">
                        <FLocat ID="cover-location" LOCTYPE="URL" xlink:href="cover.jpg"/>
                    </file>
                </xsl:if>
                <xsl:if test="$has-back-cover">
                    <file ID="back-cover-art" MIMETYPE="image/jpg" LABEL="Back Cover">
                        <FLocat ID="back-cover-location" LOCTYPE="URL" xlink:href="back-cover.jpg"/>
                    </file>
                </xsl:if>
            </fileGrp>    
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="document-sections">
    	<xsl:message>Chunk count (METS): <xsl:value-of select="count($chunks)"/></xsl:message>
        <fileGrp ID="html-sections">
        <xsl:for-each select="$chunks">
            <xsl:variable name="filename">
                <xsl:call-template name="get-chunk-filename"/>
            </xsl:variable>
            <file MIMETYPE="application/xhtml+xml">
                <xsl:attribute name="ID">
                    <xsl:call-template name="get-chunk-id"/>
                </xsl:attribute>
                <FLocat LOCTYPE="URL">
                    <xsl:attribute name="ID">
                        <xsl:call-template name="get-chunk-id"/>
                        <xsl:text>-location</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="xlink:href">
                    	<xsl:text>content/</xsl:text>
                        <xsl:value-of select="$filename"/>
                    </xsl:attribute>
                </FLocat>
            </file>
            
        </xsl:for-each>
        </fileGrp>
    </xsl:template>
    
    <xsl:template name="struct-map">
        <structMap ID="book-structure">
            <xsl:attribute name="LABEL" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt/tei:title[1]"/>
            <xsl:for-each select="$chunks">
                <xsl:variable name="thisChunk" select="."/>
                <div TYPE="section">
                    <xsl:variable name="fileid">
                        <xsl:call-template name="get-chunk-id"/>
                    </xsl:variable>
                    <xsl:attribute name="LABEL">
                        <xsl:call-template name="get-section-title"/>
                    </xsl:attribute>
                    <fptr FILEID="{ $fileid }">
                    <xsl:for-each select=".//tei:pb">
                        <area ID="page-{ @n }" FILEID="{$fileid}" BEGIN="{ @xml:id }"
                        BETYPE="IDREF">
                            <xsl:if test="not(position() = last())">
                                <xsl:attribute name="END" select="following::tei:pb[1]/@xml:id"/>
                            </xsl:if>
                        </area>
                    </xsl:for-each>
                    <xsl:for-each select=".//tei:ref[@type='noteref']">
                        <xsl:variable name="refid" select="if (@xml:id) then @xml:id else concat('noteref-', substring(@target,2))"/>
                        <area ID="ptr-{ $refid }" FILEID="{$fileid}" BETYPE="IDREF"
                            BEGIN="{$refid}"/>
                    </xsl:for-each>
                    </fptr>
                </div>
            </xsl:for-each>
        </structMap>
    </xsl:template>

</xsl:stylesheet>
