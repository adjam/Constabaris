<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:lcrm="https://lcrm.lib.unc.edu/ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0"
    exclude-result-prefixes="tei opf xs lcrm">
    
    <!-- core XSLT templates; this stylesheet should be imported (directly or indirectly) by
    anything -->
    
    <xsl:import href="tables.xsl"/>
    
    <xsl:import href="bibliography.xsl"/>
    
    <xsl:import href="notes.xsl"/>
    
    <xsl:template match="tei:div">
        <div>
            <xsl:call-template name="transcribe-id"/>
            <xsl:if test="@type">
            	<xsl:attribute name="class">
            	    <xsl:value-of select="@type"/>
                    <xsl:if test="@subtype">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="@subtype"/>
                    </xsl:if>
            	</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:head">
        <xsl:choose>
            <xsl:when test="@type = 'chapterNumber'">
                <h2 class="chapterNumber"><xsl:apply-templates/></h2>
            </xsl:when> 
            <xsl:when test="@type = 'chapterTitle'">
                <h2 class="chapterTitle"><xsl:apply-templates/></h2>
            </xsl:when>
            
            <xsl:when test="@type= 'title'">
                <xsl:choose>
                    <xsl:when test="./tei:div/@type='chapter'">
                        <h2 class="chapterTitle"><xsl:apply-templates/></h2>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2 class="sectionTitle"><xsl:apply-templates/></h2>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="containedText" select="."/>
                <xsl:if test="string-length(normalize-space($containedText)) &gt; 0">
                    <h3>
                        <xsl:if test="@type">
                            <xsl:attribute name="class"><xsl:value-of select="@type"/></xsl:attribute>
                        </xsl:if>
                        <xsl:apply-templates/>
                    </h3>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:figDesc">
        <span class="figDesc">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:p">
            <p>
                <xsl:call-template name="transcribe-or-assign-id"/>
                <xsl:apply-templates/>
            </p>
    </xsl:template>
    
    <xsl:template match="tei:titlePage">        
        <div class="titlePage">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:byline">
        <div class="byline">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:docImprint">
        <div class="imprint">
            <span class="publisher">
                <xsl:value-of select="tei:publisher"/>
            </span>
            <span class="pubPlace">
                <xsl:value-of select="tei:pubPlace"/>
            </span>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:closer">
        <div class="closer">
            <xsl:if test="@xml:id">
                <xsl:attribute name="xml:id" select="@xml:id"/>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:lb">
        <br />
    </xsl:template>
    
    <!-- note that the tei:l elements had better not themselves contain paragraph
	 elements -->
    <xsl:template match="tei:lg">
        <div>
            <xsl:attribute name="class">
                <xsl:text>line-group</xsl:text>
                <xsl:if test="@type">
                    <xsl:value-of select="concat(' ', @type)"/>
                </xsl:if>
            </xsl:attribute>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:l">
        <xsl:apply-templates/>
        <br />
    </xsl:template>
    
    <!-- check whether the path is redundant -->
    <xsl:template match="tei:titlePage/tei:docTitle">
        <h2 class="title"><xsl:apply-templates select="tei:titlePart[@type='main']"/></h2>
        <xsl:if test="tei:titlePart[@type='sub']">
            <h3 class="subtitle"><xsl:apply-templates select="tei:titlePart[@type='sub']"/></h3>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:seg">
        <span>
            <xsl:call-template name="transcribe-id"/>
            <xsl:call-template name="rend-to-class"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:emph">
        <em><xsl:call-template name="rend-to-class"/><xsl:apply-templates/></em>
    </xsl:template>
    
    <xsl:template match="tei:del">
        <del><xsl:apply-templates/></del>
    </xsl:template>
    
    <xsl:template match="tei:hi">
        <xsl:choose>
            <xsl:when test="@rend">
                <xsl:choose>
                    <xsl:when test="@rend='italic'"><i><xsl:apply-templates/></i></xsl:when>
                    <xsl:when test="@rend='italics'"><i><xsl:apply-templates/></i></xsl:when>
                    <xsl:when test="@rend='bold'"><b><xsl:apply-templates/></b></xsl:when>
                    <xsl:when test="@rend='underline'"><span class="underline"><xsl:apply-templates/></span></xsl:when>
                    <xsl:when test="@rend='superscript'"><sup><xsl:apply-templates/></sup></xsl:when>
                    <xsl:when test="@rend='subscript'"><sub><xsl:apply-templates/></sub></xsl:when>
                    <xsl:otherwise><span class="{@rend}"><xsl:apply-templates/></span></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <em><xsl:apply-templates/></em>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:q">
        <q><xsl:apply-templates/></q>
    </xsl:template>
    
    <xsl:template match="tei:quote">
        <blockquote>
            <xsl:if test="@xml:id">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="@rend">
                <xsl:attribute name="class"><xsl:value-of select="@rend"/></xsl:attribute>
            </xsl:if><div>
                <xsl:apply-templates/>
            </div>
        </blockquote>
    </xsl:template>
    
    <xsl:template match="tei:date">
        <span class="date">
            <xsl:attribute name="title">
            <xsl:choose>
                <xsl:when test="@when">
                    <xsl:value-of select="@when"/>
                </xsl:when>
                <xsl:when test="from">
                    <xsl:value-of select="@from"/>
                    <xsl:text> to </xsl:text>
                    <xsl:value-of select="@to"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>date: </xsl:text>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:div[@type='endnotes']">
        <div class="endnotes">
            <xsl:if test="not(tei:head)">
                <h2>Endnotes</h2>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:div[@type='endnotes']//tei:note">
            <div class="note">
                <div class="noteref">
                    <xsl:attribute name="id" select="@xml:id"/>
                    <xsl:variable name="target-id">
                    <xsl:call-template name="backreference-id">
                        <xsl:with-param name="reference-id" select="@xml:id"/>
                    </xsl:call-template>
                    </xsl:variable>
                    <a href="{concat('#', $target-id)}">
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
    
    <xsl:template match="tei:pb">
        <span class="pagenum" id="{@xml:id}" title="Top of page {@n}"><a href="#{@xml:id}"><xsl:value-of select="@n"/></a></span>
        <xsl:if test="local-name(following-sibling::*[1]) = 'pb'"><div class="pageblank">[ blank page ]</div></xsl:if>     
    </xsl:template>
    
    <xsl:template name="transcribe-id">
        <xsl:if test="@xml:id">
            <xsl:attribute name="id" select="@xml:id"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="transcribe-or-assign-id">
        <xsl:attribute name="id" select="if (@xml:id) then @xml:id else generate-id(.)"/>
    </xsl:template>
    
    <xsl:template name="rend-to-class">
        <xsl:if test="@rend">
            <xsl:attribute name="class"><xsl:value-of select="@rend"/></xsl:attribute>
        </xsl:if> 
    </xsl:template>
    
    
    <xsl:template match="tei:list[not(@type)]">
        <ul class="bulleted">
            <xsl:for-each select="tei:item">
                <li><xsl:call-template name="transcribe-id"/><xsl:apply-templates/></li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    
    
    <!-- note that this matches lists that DO have a type attribute -->
    <xsl:template match="tei:list[@type != 'gloss' and @type !='abbreviations']">
        <!-- expectation: 'simple' will have list-style-type: none, 
            'bulleted' is a standard 'ul', and 'ordered' is an ol--> 
        <xsl:variable name="listtype" select="if (@type) then @type else 'simple'"/>
        <xsl:element name="{if ( $listtype = 'ordered' ) then 'ol' else 'ul' }">
            <xsl:attribute name="class"
                select="$listtype"/>
            <xsl:for-each select="tei:item">
                <li><xsl:call-template name="transcribe-id"/><xsl:apply-templates/></li>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
    
    <!-- items in a 'gloss' list have labels --> 
    <xsl:template match="tei:list[@type='gloss' or @type='abbreviations']">
        <dl class="{@type}">
            <xsl:for-each select="tei:label">
                <dt><xsl:call-template name="transcribe-id"/><xsl:apply-templates/></dt>
                <dd><xsl:apply-templates select="following-sibling::tei:item[1]"/></dd>
            </xsl:for-each>
        </dl>
    </xsl:template>
    
    <xsl:template name="graphic-url">
    	<xsl:text>@work_media_url@</xsl:text>
    	<xsl:value-of select="tei:graphic/@url"/>
    </xsl:template>

    <xsl:template match="tei:figure">
        <xsl:variable name="src">
        	<xsl:choose>
        		<xsl:when test="tei:graphic/@decls">
        			<xsl:variable name="declTarget" select="substring-after(tei:graphic/@decls, '#')"/>
        			<xsl:choose>
        				<xsl:when test="id($declTarget)/@status = 'restricted'">
        					<xsl:text>@image_not_available@</xsl:text>
        				</xsl:when>
        				<xsl:otherwise>
        					<xsl:call-template name="graphic-url"/>
        				</xsl:otherwise>
        			</xsl:choose>
        		</xsl:when>
        		<xsl:otherwise>
        			<xsl:call-template name="graphic-url"/>
	            </xsl:otherwise>
        	</xsl:choose>            
        </xsl:variable>
        <span class="figure">
            <xsl:call-template name="transcribe-or-assign-id"/>
            <img src="{$src}" alt="Figure {@n}">
            	<xsl:if test="starts-with($src,'@image_not_available')">
            		<xsl:attribute name="class">unavailable</xsl:attribute>
            	</xsl:if>
            </img>
            <xsl:if test="starts-with($src,'@image_not_available')">
            		<span class="copyright-message">
            			<xsl:apply-templates select="id(substring-after(tei:graphic/@decls,'#'))/*"/>
            		</span>
            	</xsl:if>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:fw"/>

    <xsl:template match="tei:epigraph">
      <div class="epigraph">
	<xsl:apply-templates/>
      </div>
    </xsl:template>

    <xsl:template match="tei:quote/tei:bibl">
      <p class="citation">
	<xsl:apply-templates/>
      </p>
    </xsl:template>
    
    <xsl:template match="tei:sp">
        <dl class="speech">
            <dt><xsl:apply-templates select="tei:speaker"/></dt>
            <dd>
                <xsl:apply-templates select="tei:p | tei:l | tei:lg | tei:seg | tei:stage | tei:said"/>
            </dd>
        </dl>
    </xsl:template>
    
    <xsl:template match="tei:said">
        <span class="said"><xsl:apply-templates/></span>
    </xsl:template>
    
   
    
    
    <xsl:template match="tei:listBibl">
        <ul class="bibliography-list">
            <xsl:apply-templates select="tei:bibl" mode="bibliography"/>    
        </ul>
    </xsl:template>
    
    <xsl:template match="tei:bibl" mode="bibliography">
        <li>
            <xsl:apply-templates select="tei:pb"/>
            <xsl:apply-templates mode="bibliography"/>
            <xsl:call-template name="make-coins"/>
        </li>
    </xsl:template>
    
    <!-- passthrough to no-mode handling ... I think -->
    <xsl:template match="tei:hi" mode="bibliography">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:title" mode="bibliography">
        <span class="bibl-title"><xsl:apply-templates/></span>
    </xsl:template>
    
    <xsl:template match="tei:author" mode="bibliography">
        <span class="author-name"><xsl:apply-templates/></span>
    </xsl:template>
    <xsl:template match="tei:editor" mode="bibliography">
        <span class="editor-name"><xsl:apply-templates/></span>
    </xsl:template>

    <xsl:template match="tei:pubPlace" mode="bibliography">
        <span class="location pub-place"><xsl:apply-templates/></span>
    </xsl:template>

    <xsl:template match="tei:choice[tei:abbr]">
      <abbr>
	<xsl:attribute name="title">
		<xsl:value-of select="tei:expan"/>
	</xsl:attribute>
	<xsl:apply-templates select="tei:abbr"/>
      </abbr>
    </xsl:template>
    
    <xsl:template match="tei:ref" mode="bibliography">
        <xsl:apply-templates select="."/>
    </xsl:template>
    
    <xsl:template match="tei:milestone[@unit='line']">
        <br class="milestone" />
    </xsl:template>
    
   
</xsl:stylesheet>
