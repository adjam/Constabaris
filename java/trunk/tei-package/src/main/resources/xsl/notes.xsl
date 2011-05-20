<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
      xmlns:tei="http://www.tei-c.org/ns/1.0"
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:lcrm="http://lcrm.lib.unc.edu/ns"
      exclude-result-prefixes="xs tei lcrm"
      version="2.0">
    
    <xsl:param name="DEBUG" select="false()"/>
    
 
    <!-- key that maps ids on things that are referred to to the things that refer to them. 
      e.g. <note xml:id="boogedy"> ... </note> => <ref target="#boogedy"></ref>
      
      so key('references', 'boogedy') will yield up the ref element 
      -->
    <xsl:key name="references" match="//*[starts-with(@target, '#')]" use="substring-after(@target, '#')"/>
    
    <!-- suppress output of num elements inside notes, as the reference mark
        will be output as a link and does not need to be included twice -->
    <xsl:template match="tei:note/tei:num"/>
    
    <!-- this template is called to find the ID of a tei:ref element that points to an element with a known
        ID; that is, if <tei:ref target="#foo" xml:id="fooref">see foo</tei:ref> 
        ...
        <tei:note xml:id="foo"><p>This is the foo note</tei:note>
        this template will return the string 'fooref' (minus quotes); if the ref element does not have an assigned
        ID, one generated via generate-id([tei:ref node]) will be called.
        
        this assists us in generating links from footnotes and endnotes back to the places in the text where the references to them occur 
    -->
    <xsl:template name="backreference-id">
        <xsl:param name="reference-id"/>
        <xsl:variable name="reference" select="key('references', $reference-id)"/>
        <xsl:value-of select="if ($reference[1]/@xml:id) then $reference[1]/@xml:id else generate-id($reference[1])"/>        
    </xsl:template>
    
    <!-- this template is called to render notes 'inline', so they can be displayed even if the note body is in a different
        section -->
    <xsl:template name="generate-inline-note">
        <xsl:param name="targetId" />
        <xsl:param name="href-value" />
        <xsl:param name="reftext" />
        <!-- see about replacing this with a name-check on the context node -->
        <xsl:param name="virtualRef" select="false()"/>
        <span class="reference">
            <xsl:choose>
               <!-- for notes that don't have a literal ref element, we always want to use a generated ID 
               even if the actual ID has been assigned  -->
                    <xsl:when test="$virtualRef">
                        <xsl:attribute name="id" select="generate-id(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="id" select="if (@xml:id) then @xml:id else generate-id(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            [&#160;<a href="{$href-value}"><xsl:value-of select="$reftext" /></a>&#160;]
            <xsl:variable name="targetNote" select="if (id($targetId)) then id($targetId) else ."/>
            <span class="inline-note {@type}">
                <xsl:apply-templates select="$targetNote" mode="inline" />
            </span>
        </span>
    </xsl:template>
    
    <!-- this function processes ref@type=identifer @target values; refs of this type take the form
        [identifier type]:identifier
        The function returns a sequence with three text node members
        (1) identifier type (e.g. 'doi', 'isbn')
        (2) identifier value (e.g. the DOI or ISBN)
        (3) a link that is likely to resolve for that identifier (e.g. a link to dx.doi.org or worldcat)
    -->
    <xsl:function name="lcrm:identifierLink" as="item()*">
        <xsl:param name="target"/>
        <xsl:variable name="prefix" select="substring-before($target,':')"/>
        <xsl:variable name="identifier" select="lower-case(substring-after($target, ':'))"/>
        <!-- yeah, I thought I could do this with a single select and a sequence constructor.  I was wrong. -->
        <xsl:choose>
            <xsl:when test="$prefix='doi'">
                <xsl:value-of select="$prefix"/>
                <xsl:value-of select="$identifier"/>
                <xsl:value-of select="concat('http://dx.doi.org/',$identifier)"/>
            </xsl:when>            
            <xsl:when test="index-of(('isbn', 'issn', 'oclc'), $prefix)">
                <xsl:value-of select="$prefix"/>
                <xsl:value-of select="$identifier"/>
                <xsl:value-of select="concat('http://www.worldcat.org/',$prefix, '/', $identifier)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Warning: unrecogized 'identifier' reference '<xsl:value-of select="$target"/>'</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <!-- this template is used to calculate the link text for internal references.
         generally: if the tei:ref node (assumed to be the context node)
         has children, call apply-templates; next see if the node
         referred to has an @n attribute, use that, and if not that then put out an 
         errorish looking text that nonetheless points to the referent.
    -->
    <xsl:template name="reference-marker">
        <xsl:param name="referenceNode"/>
        <xsl:choose>
            <xsl:when test="text()[normalize-space(.)]|*">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="$referenceNode/@n">
                <xsl:value-of select="$referenceNode/@n"/>
            </xsl:when>
            <xsl:otherwise>
                <span style="color: red; font-weight: bold">[<xsl:value-of select="$referenceNode"/>]</span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="uriref">
        <a href="{@target}" class="offsite"><xsl:apply-templates/></a>
    </xsl:template>
    
    <xsl:template name="identifierref">
        <xsl:variable name="linkParts" select="lcrm:identifierLink(@target)" as="item()*"/>
        <xsl:choose>
            <xsl:when test="$linkParts">
                <a href="{ $linkParts[3] }" class="{ $linkParts[1] }">
                    <xsl:choose>
                        <xsl:when test="normalize-space(.)"><xsl:apply-templates/></xsl:when>
                        <!-- alternately, we could output the identifier -->
                        <xsl:otherwise><xsl:value-of select="@target"/></xsl:otherwise>
                    </xsl:choose>
                </a>
            </xsl:when>
            <xsl:otherwise>unknown link: <xsl:value-of select="@target"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
        
    <!-- there are a lot of reference types, most of which point to other places in the document.  Others
        point outside the document; I tried matching on @type, but it's a bit of a hodgepodge and so this 
        approach with a big xsl:choose made the logic easier to follow.
    -->
    <xsl:template match="tei:ref">
        <xsl:choose>
            <xsl:when test="@type='uriref'"> <!-- simple link to outside world -->
                <xsl:call-template name="uriref"/>
            </xsl:when>
            <xsl:when test="@type='identifier'"><!-- link template via identifer, e.g doi:[doi] or isbn:[isbn] -->
                <xsl:call-template name="identifierref"/>
            </xsl:when>
            <xsl:otherwise><!-- probably an IDREF inside the document, so we need to find the chunk to which it points -->
                <xsl:variable name="targetId" select="if (starts-with(@target, '#')) then substring(@target, 2) else @target"/>
                <xsl:variable name="resolvedHref">
                    <xsl:call-template name="resolve-internal-reference">
                        <xsl:with-param name="targetId" select="$targetId"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="referenceNode" select="id($targetId)"/>
                <xsl:variable name="reftext">
                    <xsl:call-template name="reference-marker">
                        <xsl:with-param name="referenceNode" select="$referenceNode"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                        <xsl:when test="@type='noteref' or @type='tablenote'">
                            <xsl:call-template name="generate-inline-note">
                                <xsl:with-param name="targetId" select="$targetId"/>
                                <xsl:with-param name="href-value" select="$resolvedHref"/>
                                <xsl:with-param name="reftext" select="$reftext"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="{$resolvedHref}" class="{@type}">
                                <xsl:attribute name="id" select="if (@xml:id) then @xml:id else generate-id(.)"/>
                                <xsl:value-of select="$reftext"/>
                            </a>
                        </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- notes that are specified inline but not rendered inline
         we want to render a reference to the note which MUST be output by another template
         into the same 'chunk' (i.e. 'footnotes' where we're talking about the foot of the HTML page).
         
         Note that for the ID on the reference, we'll have to call generate-id(.) and can't use
         any assigned IDs, because they will be used in the later rendering.
         
         -->
    <xsl:template match="tei:note[not(ancestor::div[@type='endnotes']) and not(@place='inline')]">
        <xsl:call-template name="generate-inline-note">
            <xsl:with-param name="targetId" select="@xml:id"/>
            <xsl:with-param name="href-value" select="concat('#',@xml:id)"/>
            <xsl:with-param name="reftext" select="if (@n) then @n else 'note'"/>
            <xsl:with-param name="virtualRef" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    
    <!--
    
    <xsl:template match="tei:ref[@type='noteref']">
        <xsl:variable name="targetId" select="if (starts-with(@target, '#')) then substring(@target,2) else @target"/>
        <xsl:message>Calling resolve-internal-reference with targetId = '<xsl:value-of select="$targetId"/>'</xsl:message>
        <xsl:variable name="href-value">
            <xsl:call-template name="resolve-internal-reference">
                <xsl:with-param name="targetId" select="$targetId"/>
            </xsl:call-template>
        </xsl:variable>
       
        <xsl:variable name="referenceNode" select="id($targetId)"/>
        <xsl:choose>
            <xsl:when test="$referenceNode">
                <xsl:variable name="reftext">
                    <xsl:choose>
                        <xsl:when test="child::*">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:when test="$referenceNode/@n">
                            <xsl:value-of select="$referenceNode/@n"/>
                        </xsl:when>
                        <xsl:otherwise>reference to '<xsl:value-of select="$targetId"/> has no child content and target is missing @n</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="@type='noteref' or @type='tablenote'">
                    <xsl:call-template name="generate-inline-note">
                        <xsl:with-param name="targetId" select="$targetId"/>
                        <xsl:with-param name="href-value" select="$href-value"/>
                        <xsl:with-param name="reftext" select="$reftext"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">Unable to locate reference node with id '<xsl:value-of select="$targetId"/>'</xsl:message>
                <span style="color: red; font-weight: bold">unable to find reference node with id <xsl:value-of select="$targetId"/></span>
            </xsl:otherwise>
        </xsl:choose>       
    </xsl:template>
    -->
    
    <!-- this template should be called to emit all footnotes for a specified chunk *as part of that chunk* -->
    <xsl:template match="tei:note[@type='footnote' or @type='tablenote']" mode="footnotes">
      <xsl:variable name="referenceId"
          select="generate-id(.)"/>
      <xsl:variable name="firstReference" select="key('references', @xml:id)[1]"/>
      <div class="note footnote" id="{ @xml:id }">
         <div class="noteref">
            <a href="{ concat('#', $referenceId) }">
                <xsl:value-of select="@n"/>
            </a>
         </div>
         <div class="notebody">
             <xsl:apply-templates mode="inline"/>
          </div>
          <div class="clearblock">&#160;</div>
     </div>
    </xsl:template>
    
    <!--
    <xsl:template match="tei:ref[@type='pageref']">
        <xsl:variable name="targetId" select="if (starts-with(@target, '#')) then substring(@target,2) else @target"/>
        <xsl:variable name="href-value">
            <xsl:call-template name="resolve-internal-reference">
                <xsl:with-param name="targetId" select="$targetId"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="referenceNode" select="id($targetId)"/>
        <xsl:choose>
            <xsl:when test="$referenceNode">
                <xsl:variable name="reftext">
                    <xsl:choose>
                        <xsl:when test="text()">
                            <xsl:value-of select="text()"/>
                        </xsl:when>
                        <xsl:when test="$referenceNode/@n">
                            <xsl:value-of select="$referenceNode/@n"/>
                        </xsl:when>
                        <xsl:otherwise>page break with id '<xsl:value-of select="$targetId"/>  is missing @n</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <span class="reference">
                    <xsl:attribute name="id" select="if (@xml:id) then @xml:id else generate-id(.)"/>
                    [&#160;<a href="{$href-value}"><xsl:value-of select="$reftext"/></a>&#160;]
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span style="color: red; font-weight: bold">unable to find reference node with id <xsl:value-of select="$targetId"/></span>
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
    -->
    <!--
    <xsl:template match="tei:note[parent::tei:p]">
        <xsl:variable name="noteId" select="if (@xml:id) then @xml:id else generate-id(.)"/>
        <xsl:variable name="linkId">
            <xsl:text>ref-</xsl:text>
            <xsl:value-of select="$noteId"/>
        </xsl:variable>
        [<a id="{$linkId}" href="#{ $noteId }">
            <xsl:value-of select="@n"/>
        </a>]
        <xsl:call-template name="generate-inline-note">
            <xsl:with-param name="targetId" select="$noteId"/>
            <xsl:with-param name="href-value">
                <xsl:text>#</xsl:text>
                <xsl:value-of select="$linkId"/>
            </xsl:with-param>
            <xsl:with-param name="reftext" select="@n"/>
            <xsl:with-param name="virtualref" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    -->
    
 
    <!-- called to render an inline footnote -->
    <xsl:template match="tei:note" mode="inline">
        <xsl:if test="$DEBUG">
            <xsl:message><xsl:value-of select="@xml:id"/> -- refs <xsl:copy-of select="key('noterefs', @xml:id)"/></xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="tei:p">
                <xsl:for-each select="tei:p">
                    <!-- NOTE: this horrible dodge is required when the note is rendered inside an XHTML p element -->
                    <span class="paragraph">
                        <xsl:apply-templates/>
                    </span>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- this is a minimal template that is designed to be overriden; stylesheets that emit multiple 'chunks' for example would need
        to ensure that references point to the right filename -->
    <xsl:template name="resolve-internal-reference">
        <xsl:param name="targetId"/>
        <xsl:value-of select="concat('#', $targetId)"/>
    </xsl:template>
    
    <!-- another do-nothing template designed for overriding; stylesheets that emit multiple 'chunks' will need a way to ensure that foot/endnotes can
        succssfully point back to the reference -->
    <xsl:template name="reverse-internal-reference">
        <xsl:param name="element-id"/>
        <xsl:value-of select="$element-id"/>
    </xsl:template>
</xsl:stylesheet>
