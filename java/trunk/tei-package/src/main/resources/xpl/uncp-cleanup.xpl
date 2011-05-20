<?xml version="1.0" encoding="UTF-8"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" 
            xmlns:tei="http://www.tei-c.org/ns/1.0"
            xmlns:lcrm="http://lcrm.unc.edu/xproc">
    <p:documentation>
        Defines pipelines that can be used to modify output from UNC Press into a more tractable format
        suitable for ingest into LCRM demo app.
    </p:documentation>
    
    <p:pipeline type="lcrm:do-cleanup">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <div class="pipeline-documentation">
            <h2>Do Cleanup</h2>
               <p>Takes a TEI P5 document encoded against UNC Press standards
               and strips off <tt>uncp-[isbn]-</tt> prefix from <tt>xml:id</tt> and targets 
                (to reduce the size of the output documents and make IDs easier to reference).
                Also generates <tt>xml:id</tt> values for footnote references (allowing them to be
                   linked to from endnotes).
               </p>
                <p class="todo">TODO: add xml:id attributes to *selected* paragraphs to allow
                annotation.</p>
            </div>
        </p:documentation>
       
        
    <p:delete match="processing-instruction('oxygen')"/>
    <!-- add xml:id attributes to all noterefs that lack 'em, so that endnotes can link back to
        the points in the document that reference them; note that generate-id(.) doesn't work w/Saxon9 in this context -->
    <p:label-elements match="tei:ref[@type='noteref' and not(@xml:id)]" label="concat('noteref-', $p:index)"/>
        
    <p:label-elements match="tei:body//tei:p[not(@xml:id) and not(name(..) = 'note')]" label="concat('p-',$p:index)"/>
    
    <!-- 'normalize' the IDs by stripping off the 'uncp-(isbn)-' prefixes -->
    <!-- N.B. Calabash uses XPath 2.0, in which the context node in replace is
	the *attribute* node; Calumet uses XPath 1.0, in which the context node
	is the elment that has the xml:id attribute ... -->
     <p:choose>
         
        <!-- OK, this is *WRONG* ... should not be matching on the product name but
             Calabash 0.9.15 does not implement p:xpath-version-available which is the
             right way to do it. -->
         <p:when test="p:system-property('p:product-name') = 'XML Calabash'">
             <lcrm:trim-ids-xpath2/>             
         </p:when>
         <p:otherwise>
             <lcrm:trim-ids-xpath1/>
         </p:otherwise>
     </p:choose>
     
    </p:pipeline>
    
    
    <p:pipeline type="lcrm:trim-ids-xpath1" xpath-version="1.0">
        <p:string-replace match="@xml:id[starts-with(., 'uncp-') and not(contains(., '-book'))]"
            replace="substring(./@xml:id, 20)"/>
        
        <!-- now we need to fix the targets that pointed at those IDs -->
        <p:string-replace match="@target[starts-with(., '#uncp-') and not(contains(., '-book'))]"
            replace="concat('#', substring(./@target, 21))"/>
    </p:pipeline>
    
    <p:pipeline type="lcrm:trim-ids-xpath2" xpath-version="2.0">
        <p:string-replace match="@xml:id[starts-with(., 'uncp-') and not(ends-with(., '-book'))]"
            replace="substring(., 20)"/>
        
        <!-- now we need to fix the targets that pointed at those IDs -->
        <p:string-replace match="@target[starts-with(., '#uncp-') and not(ends-with(., '-book'))]"
            replace="concat('#', substring(., 21))"/>
        
    </p:pipeline>
    
    <p:pipeline type="lcrm:process-references">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <div class="pipeline-documentation">
                <h2>Process References</h2>
                <p>This should be invoked after a book has been processed into multiple chunks, in order to resolve
                all of the XHTML anchor tags that refer to other 'chunks'.</p>
            </div>
        </p:documentation>
        <p:xslt version="2.0">
            <p:input port="stylesheet">
                <p:inline>
                    <xsl:stylesheet 
                        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                        version="2.0">
                        
                    </xsl:stylesheet>
                </p:inline>
                
            </p:input>
        </p:xslt>
        <p:string-replace xmlns:x="http://www.w3.org/1999/xhtml" match="//x:a[starts-with('fleebnorber', @href)]"
            replace="'florbneeber'"/>
    </p:pipeline>
    
    <p:pipeline type="lcrm:map-references">
            <p:input port="secondary" sequence="true"/>
            <p:for-each>
                <p:identity/>
            </p:for-each>
        
    </p:pipeline>
</p:library>
