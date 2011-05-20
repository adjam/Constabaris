<?xml version="1.0" encoding="UTF-8"?>
<?oxygen RNGSchema="../../../../../../../Downloads/xproc.rng" type="xml"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:lcrm="http://lcrm.unc.edu/xproc"
    name="generate-mets">
    
    
    <p:input port="source" primary="true"/>
    
    <p:output port="result" primary="true">
        <p:pipe step="mets-output" port="result"/>
    </p:output>


    <p:input port="parameters" kind="parameter" primary='true'/>
      
    <p:output port="normalized-ingest-document">
    	<p:pipe step="do-cleanup" port="result"/>
    </p:output>
    
    <p:output port="secondary" sequence="true">
        <p:pipe step="create-chunks" port="secondary"/>
    </p:output>
    
    <p:option name="outputBase" select="'/tmp/xproc-output'"/>
    
    <p:log port="parameters" href="/tmp/parameters.log"/>
    
    <p:import href="uncp-cleanup.xpl"/>
    
    <lcrm:do-cleanup name="do-cleanup"/>
    
    <p:store encoding="utf-8" indent="true" name="store-tei">
        <p:with-option name="href" select="concat($outputBase, '/tei.xml')"/>
        <p:input port="source">
            <p:pipe port="result" step="do-cleanup"/>
        </p:input>
    </p:store>

    <p:xslt name="create-chunks" version="2.0">
        
        <p:input port="source">
            <p:pipe step="do-cleanup" port="result"/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xsl/driver.xsl"/>
        </p:input>
        <p:with-param name="outputDirectory" select="concat($outputBase, '/content')">
            <p:pipe step="generate-mets" port="parameters"/>
        </p:with-param>
        <p:input port="parameters">
            <p:pipe step="generate-mets" port="parameters"/>
        </p:input>
       
    </p:xslt>
    
    <p:sink/>
    <!--
    <p:store encoding="utf-8" indent="true" omit-xml-declaration="false">
   	    <p:with-option name="href" select="concat($outputDirectory,'/chunks.xml')"/>
    </p:store>
    -->

<!--
    <p:store encoding="utf-8" indent="true" omit-xml-declaration="false">
        <p:with-option name="href" select="concat($outputDirectory, '/chunks.xml')"/>
    </p:store>
    -->
    
    <p:for-each>
        <p:iteration-source>
            <p:pipe step="create-chunks" port="secondary"/>
        </p:iteration-source>

        <p:store encoding="utf-8" undeclare-prefixes="true" name="store-html">
            <p:with-option name="href" select="p:base-uri()"/>
        </p:store>
    </p:for-each>
    
    <p:xslt name="mets-output" version="2.0">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <div>
                <h2>METS Output</h2>
            </div>
            <p>
                Generates the METS output document based on the "cleaned up" input.  METS output
                will be used by the ingest process to create Works and Segments.
            </p>
        </p:documentation>
        <p:input port="source">
            <p:pipe step="do-cleanup" port="result"/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xsl/tei2mets.xsl"/>
        </p:input>
    </p:xslt>
    
  </p:declare-step>
  
