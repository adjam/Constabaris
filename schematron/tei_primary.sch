<?xml version="1.0" encoding="UTF-8"?>
<iso:schema xmlns:iso="http://purl.oclc.org/dsdl/schematron" xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:file="java:java.io.File"
	xmlns:url="java:java.net.URL" xmlns:lfn="http://lcrm.unc.edu"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2" schemaVersion="ISO19757-3">
	<iso:ns uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
	<iso:ns uri="http://lcrm.unc.edu" prefix="lfn"/>
	<iso:ns uri="java:java.net.URL" prefix="url"/>

	<!--  	
		iso_dsdl_include.xsl  tei_primary.sch > tei_1.sch
		iso_abstract_expand.xsl  tei_1.sch > tei_2.sch
		iso_svrl_for_xslt2  tei_2.sch > tei_schematron_final.xsl
		tei_test_final.xsl  uncp-978080724511-book.xml > results.xml
		iso_html.xsl  results.xml > brief-results.html
	-->

	<iso:title>ISO schematron file for TEI Monographs.</iso:title>

	<!-- postPublication -->

	<iso:let name="total_pages" value="count(//tei:pb)"/>
	<iso:let name="fm_pages" value="count(/tei:TEI/tei:text/tei:front//tei:pb)"/>
	<iso:let name="body_pages" value="count(/tei:TEI/tei:text/tei:body//tei:pb)"/>
	<iso:let name="bm_pages" value="count(/tei:TEI/tei:text/tei:back//tei:pb)"/>

	<!-- Generate Author and Title -->
	<iso:pattern id="title.checks">
		<iso:title>Title Statement</iso:title>
		<iso:rule
			context="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt">
			<iso:report
				test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt"
				role="Title" id="r1">Title Statement: <iso:value-of
					select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblFull/tei:titleStmt"
				/></iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Generate Date -->
	<iso:pattern id="doc.checks">
		<iso:title>Checking the TEI document</iso:title>
		<iso:rule context="//tei:text">
			<iso:report test="tei:body" role="Date" id="r2">Report date: <iso:value-of
					select="substring(string(current-date()), 1, 10)"/></iso:report>
		</iso:rule>
	</iso:pattern>
	
	<!-- keyword length -->
	<iso:pattern id="keyword.checks">		
		<iso:title>Checking keyword length</iso:title>
		<iso:rule context="//tei:keywords[@scheme='UNCP']/tei:list/tei:item">
			<iso:assert test="string-length(string(.))&lt;50" role="Priority1" id="a333">Keyword <iso:value-of select="position()"/> longer than 50 characters.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- CHECK FOR VALID YYYY-MM-DD -->
	<iso:pattern id="date.checks">
		<iso:rule context="/tei:TEI/tei:teiHeader//tei:date">
			<iso:assert
				test="
				string-length(normalize-space(.))=4
				and string(number(substring(normalize-space(.),1,4)))!='NaN'
				and string-length(substring(normalize-space(.),1,4))=4
				or
				string-length(normalize-space(.))=7
				and string(number(substring(normalize-space(.),1,4)))!='NaN'
				and string-length(substring(normalize-space(.),1,4))=4
				and substring(normalize-space(.),5,1)='-'
				and string(number(substring(normalize-space(.),6,2)))!='NaN'
				and string-length(substring(normalize-space(.),6,2))=2
				and number(substring(normalize-space(.),6,2))>=1
				and number(substring(normalize-space(.),6,2))&lt;=12
				or	
				string-length(normalize-space(.))=10
				and string(number(substring(normalize-space(.),1,4)))!='NaN'
				and string-length(substring(normalize-space(.),1,4))=4
				and substring(normalize-space(.),5,1)='-'
				and string(number(substring(normalize-space(.),6,2)))!='NaN'
				and string-length(substring(normalize-space(.),6,2))=2
				and number(substring(normalize-space(.),6,2))>=1
				and number(substring(normalize-space(.),6,2))&lt;=12
				and substring(normalize-space(.),8,1)='-'
				and string(number(substring(normalize-space(.),9,2)))!='NaN'
				and string-length(substring(normalize-space(.),9,2))=2
				and number(substring(normalize-space(.),9,2))>=1
				and number(substring(normalize-space(.),9,2))&lt;=31
				"
				role="Priority1" id="a33">
				<iso:name/> does not contain a valid date (YYYY-MM-DD).
			</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Variables to get Filename -->
	<iso:let name="filename" value="document-uri(.)"/>
	<iso:let name="truncate" value="tokenize(document-uri(.), '/')[last()]"/>
	<iso:let name="shortfilename" value="substring-before($truncate,'book.xml')"/>
	<iso:let name="isbn_after" value="substring-after($shortfilename,'-')"/>
	<iso:let name="isbn" value="substring-before($isbn_after,'-')"/>
	<iso:let name="figure_uri" value="substring-before(document-uri(.),'uncp-978080724511-book.xml')"/>

	<!-- Output of variables and document xml:id -->
	<iso:pattern id="PrimaryID">
		<iso:rule context="//tei:TEI">
			<iso:report test="@xml:id" role="ID" id="r3">The document id is <iso:value-of select="@xml:id"
					/> and the filename is <iso:value-of select="$truncate"/></iso:report>
			<iso:assert test="string-length($isbn)=13" role="Priority1" id="a1"
					>The ISBN should have 13 digits: <iso:value-of select="$isbn"/></iso:assert>
			<iso:assert test="$isbn castable as xs:integer" role="Priority1" id="a2"
					>The ISBN should have 13 digits: <iso:value-of select="$isbn"/></iso:assert>
			<iso:report test="//tei:pb" role="Count" id="r4">There are <iso:value-of select="$total_pages"
					/> pages in the data: <iso:value-of select="$fm_pages"/> frontmatter and <iso:value-of
					select="$body_pages+$bm_pages"/> body and backmatter.</iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Doc URI for xpath linking -->
	<iso:pattern id="docURI">
		<iso:rule context="//tei:TEI">
			<iso:report test="@xml:id" role="docURI" id="r5">
				<iso:value-of select="$filename"/>
			</iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Check author @xml:id and reg -->
	<iso:pattern id="author.checks">
		<iso:title>Checking for @xml:id in author, as well as reg</iso:title>
		<iso:p>Author ID and reg Checks</iso:p>
		<iso:rule context="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt//tei:author">
			<iso:assert test="@xml:id" role="Priority1" id="a44">Author must have @xml:id</iso:assert>
			<iso:assert test="tei:reg" role="Priority1" id="a45"
				>Author must have regularized name</iso:assert>
			<iso:assert test="tei:name/tei:forename" role="Priority1" id="a46"
				>Author must have forename</iso:assert>
			<iso:assert test="tei:name/tei:surname" role="Priority1" id="a47"
				>Author must have surname</iso:assert>
			<iso:assert test="tei:name/tei:forename[1][@type='given']" role="Priority1" id="a48"
				>Author forename must have @type='given'</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check availability element and attributes in Head -->
	<iso:pattern id="availability.checks">
		<iso:title>Checking for availability and attributes</iso:title>
		<iso:p>Header availability and attributes</iso:p>
		<iso:rule context="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt">
			<iso:assert test="tei:availability" role="Priority2" id="a39"
				>Availability statement for graphics must be present</iso:assert>
			<iso:assert test="tei:availability[@xml:id='notCleared']" role="Priority2" id="a40"
				>Availability statement with @xml:id=notCleared must be present</iso:assert>
			<iso:assert test="tei:availability[@status='restricted']" role="Priority2" id="a41"
				>Availability statement with @status=restricted must be present</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check LCSH Keywords in Head -->
	<iso:pattern id="lcsh.checks">
		<iso:title>Checking the LCSH Keywords</iso:title>
		<iso:p>All LCSH Keyword Level Checks</iso:p>
		<iso:rule context="//tei:keywords[@scheme='LCSH']">
			<iso:assert test="tei:list/tei:item" role="Priority2" id="a3"
				>LCSH keywords must be present</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check label elements for gloss list -->
	<iso:pattern id="list.checks">
		<iso:title>Checking glossary lists for correct type</iso:title>
		<iso:p>All List type Checks</iso:p>
		<iso:rule context="//tei:label">
			<iso:assert test="parent::tei:list[@type='gloss']" role="Priority1" id="a77"
				>Label elements must be in lists with type gloss.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check UNCP keywords -->
	<iso:pattern id="UNCPkeywords.checks">
		<iso:title>Checking the UNC Press Keywords</iso:title>
		<iso:p>UNCP Keywords Checks</iso:p>
		<iso:rule context="//tei:keywords[@scheme='UNCP']">
			<iso:assert test="tei:list/tei:item" role="Priority1" id="a56"
				>UNCP keywords must be present</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check Abstract -->
	<iso:pattern id="abstract.checks">
		<iso:title>Checking the Abstracts</iso:title>
		<iso:p>All Abstract Checks</iso:p>
		<iso:rule context="//tei:note[@type='abstract']">
			<iso:assert test="tei:p" role="Priority1" id="a11"
				>Text does not have an abstract.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- External links: worldcat, uncpress -->
	<iso:pattern id="links">
		<iso:rule context="//tei:note[@type='links']/tei:ref[@target]">
			<iso:report test="(@target)" role="links" id="r66">
				<iso:value-of select="(@target)"/>
			</iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Variables to get full pb id prefix -->
	<!--	<iso:let name="pb-id" value="concat('uncp-',$isbn,'-p')"/>-->

	<!-- Check pbs-->
	<iso:pattern id="pb.checks">
		<iso:title>Checking the pb Structure</iso:title>
		<iso:p>All pb Checks</iso:p>
		<iso:rule context="//tei:pb">
			<iso:assert test="ancestor::tei:div|ancestor::tei:titlePage" role="Priority1" id="a4"
				>All pb elements should be contained within divs.</iso:assert>
			<!-- add |ancestor::titlePage to catch titlepage-->
			<iso:assert test="(@xml:id)=concat('pg',@n)" role="Priority1" id="a5"
					>The pb id should have the following structure: p{pageNo}: <iso:value-of select="@xml:id"
				/>.</iso:assert>
			<iso:assert test="substring-after(@xml:id,'pg')=(@n)" role="Priority1" id="a6"
					>The id page number should be the same as the n page number: <iso:value-of
					select="@xml:id"/> should be <iso:value-of select="@n"/>.</iso:assert>
			<iso:assert test="not(parent::tei:list)" role="Priority1" id="a9"
					>All pb elements cannot be direct children of list; move <iso:value-of select="@xml:id"
				/> to item.</iso:assert>
			<iso:assert test="not(parent::tei:listBibl)" role="Priority1" id="a10"
					>All pb elements cannot be direct children of listBibl; move <iso:value-of
					select="@xml:id"/> to bibl.</iso:assert>
			<iso:assert test="not(following-sibling::*[1][self::tei:pb])" role="Priority1" id="a100"
				>Check to see if <iso:value-of select="@xml:id"/> is blank in the source. </iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Function to use count() with Roman numerals -->
	<xsl:function name="lfn:roman-value">
		<xsl:param name="input" as="xs:integer"/>
		<xsl:number value="$input" format="i"/>
	</xsl:function>

	<!-- Generate numbers for pb front-->
	<iso:pattern id="pb.front">
		<iso:title>Checking front pb Structure</iso:title>
		<iso:rule context="/tei:TEI/tei:text[1]/tei:front[1]//tei:pb">
			<iso:let name="folio"
				value="lfn:roman-value(count(preceding::tei:pb[ancestor::tei:front]) + 1)"/>
			<iso:assert test="(@n)=$folio" role="Priority1" id="a7"
					>pb elements should be numbered sequentially: <iso:value-of select="@n"
					/> should be <iso:value-of select="$folio"/></iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Generate numbers for pb body-->
	<iso:pattern id="pb.body">
		<iso:title>Checking body pb Structure</iso:title>
		<iso:rule context="/tei:TEI/tei:text[1]/tei:body[1]//tei:pb">
			<iso:let name="folio" value="count(preceding::tei:pb[ancestor::tei:body]) + 1"/>
			<iso:assert test="(@n)=$folio" role="Priority1" id="a8"
					>pb elements should be numbered sequentially: <iso:value-of select="@n"
					/> should be <iso:value-of select="$folio"/></iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Generate numbers for pb back-->
	<iso:pattern id="pb.back">
		<iso:title>Checking back pb Structure</iso:title>
		<iso:rule context="/tei:TEI/tei:text[1]/tei:back[1]//tei:pb">
			<iso:let name="folio_body" value="count(/tei:TEI/tei:text/tei:body//tei:pb)"/>
			<iso:let name="folio_bm"
				value="$folio_body + (count(preceding::tei:pb[ancestor::tei:back]) + 1)"/>
			<iso:assert test="(@n)=$folio_bm" role="Priority1" id="a79"
					>pb elements should be numbered sequentially: <iso:value-of select="@n"
					/> should be <iso:value-of select="$folio_bm"/></iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Count divs in body -->
	<iso:pattern id="body.checks">
		<iso:title>Checking the body Structure</iso:title>
		<iso:p>All body Level Checks</iso:p>
		<iso:rule context="//tei:body">
			<iso:report test="count(tei:div)" role="Count" id="r6"
					>Total number of divs in body: <iso:value-of select="count(tei:div)"/></iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Count elements in text -->
	<iso:pattern id="count.checks">
		<iso:title>Checking Counts for Elements</iso:title>
		<iso:p>All Count Checks</iso:p>
		<iso:rule context="/tei:TEI/tei:text[1]">
			<iso:report test="count(//tei:figure)" role="Count" id="r7"
					>Total number of figures: <iso:value-of select="count(//tei:figure)"/></iso:report>
			<iso:report test="count(//tei:graphic)" role="Count" id="r8"
					>Total number of graphics: <iso:value-of select="count(//tei:graphic)"/></iso:report>
			<iso:report test="count(//tei:note[@type='abstract'])" role="Count" id="r15"
					>Total number of abstracts: <iso:value-of select="count(//tei:note[@type='abstract'])"
				/></iso:report>
			<iso:report test="count(//tei:note[@type='endnote'])" role="Count" id="r9"
					>Total number of endnotes: <iso:value-of select="count(//tei:note[@type='endnote'])"
				/></iso:report>
			<iso:report test="count(//tei:note[@type='footnote'])" role="Count" id="r10"
					>Total number of footnotes: <iso:value-of select="count(//tei:note[@type='footnote'])"
				/></iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Check for Greek -->
	<iso:pattern id="greek.check">
		<iso:title>Check for Greek</iso:title>
		<iso:rule context="*[text()[matches(.,'\p{IsGreek}')]]">
			<iso:report test="matches(.,'\p{IsGreek}')" role="Unicode" id="r11"
					>Greek text should be compared with the print version to ensure accuracy: <iso:value-of
					select="concat(substring(.,1,35),' . . .')"/></iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Check for GreekExtended -->
	<iso:pattern id="greekextended.check">
		<iso:title>Check for GreekExtended</iso:title>
		<iso:rule context="*[text()[matches(.,'\p{IsGreekExtended}')]]">
			<iso:report test="matches(.,'\p{IsGreekExtended}')" role="Unicode" id="r12"
					>GreekExtended text should be compared with the print version to ensure accuracy: <iso:value-of
					select="concat(substring(.,1,35),' . . .')"/></iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Check for Hebrew -->
	<iso:pattern id="hebrew.check">
		<iso:title>Check for Hebrew</iso:title>
		<iso:rule context="*[text()[matches(.,'\p{IsHebrew}')]]">
			<iso:report test="matches(.,'\p{IsHebrew}')" role="Unicode" id="r13"
					>Hebrew text should be compared with the print version to ensure accuracy: <iso:value-of
					select="concat(substring(.,1,35),' . . .')"/></iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- AC's function for checking that referenced graphics exist; follows with the path function below -->
	<xsl:function name="lfn:file-exists">
		<xsl:param name="image-path" as="xs:string"/>
		<xsl:variable name="full-path" select="lfn:get-image-filesystem-path($filename,$image-path)"
			as="xs:string"/>
		<xsl:variable name="theFile" select="file:new($full-path)"/>
		<!--		<xsl:message>
			<xsl:value-of select="file:get-absolute-path($theFile)"/>
		</xsl:message>-->
		<xsl:choose>
			<xsl:when test="file:exists($theFile)">
				<xsl:message><xsl:value-of select="$full-path"/> exists</xsl:message>
				<xsl:text>1</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message><xsl:value-of select="$full-path"/> not found</xsl:message>
				<xsl:text>0</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Finds the path on the filesystem for a referenced image -->
	<!-- The first parameter is the URI of the document being validated, the second is the path of the image -->
	<xsl:function name="lfn:get-image-filesystem-path">
		<xsl:param name="base-uri" as="xs:anyURI"/>
		<xsl:param name="relative-path" as="xs:string"/>
		<xsl:choose>
			<xsl:when test="starts-with($relative-path, '/')">
				<xsl:value-of select="$relative-path"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="full-uri" select="resolve-uri($relative-path, $base-uri)"/>
				<xsl:variable name="url" select="url:new($full-uri)"/>
				<xsl:value-of select="url:get-path($url)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Check Extant Graphics -->
	<iso:pattern id="graphic.check">
		<iso:title>Check for Extant Graphics</iso:title>
		<iso:rule context="//tei:graphic[@url]">
			<iso:assert test="lfn:file-exists(@url)=1" role="Priority1" id="a13">
				<iso:value-of select="@url"/> not found.
			</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check Permissions on Graphics	-->
	<iso:pattern id="graphic.Permissions.check">
		<iso:title>Check for Permissions on Graphics</iso:title>
		<iso:rule context="//tei:graphic">
			<iso:report test="(@decls='#notCleared')" role="permissions" id="r19"
					>
				Permissions not cleared for <iso:value-of select="@url"/>
			</iso:report>
		</iso:rule>
	</iso:pattern>

	<!-- Variable to get hyphenated ISBN -->
	<iso:let name="isbn_hyphen"
		value="concat(substring($isbn,1,3),'-',substring($isbn,4,1),'-',substring($isbn,5,4),'-',substring($isbn,9,4),'-',substring($isbn,13,1))"/>

	<!-- Check all ISBN of filename against ISBN in publicationStmt -->
	<iso:pattern id="id_pub.checks">
		<iso:title>Checking the ID against the header</iso:title>
		<iso:p>ISBN ID check</iso:p>
		<iso:rule context="//tei:idno[@type='ISBN']">
			<iso:assert test="current()=$isbn" role="Priority1" id="a22"
					>The ISBN in the header does not match the filename: <iso:value-of select="current()"
					/> should be <iso:value-of select="$isbn"/></iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check all ref target against note xml:id -->
	<iso:pattern id="target.checks">
		<iso:title>Checking the ref target</iso:title>
		<iso:p>All ref target Level Checks</iso:p>
		<iso:rule context="tei:ref[@type='noteref']">
			<iso:assert test="substring(@target,2)=//tei:note/@xml:id[.]" role="Priority1" id="a23"
					>All ref targets must point to existing note xml:ids. <iso:value-of
					select="substring(@target,2)"/> does not exist.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check all pageref against pb -->
	<iso:pattern id="pb-pageref.checks">
		<iso:title>Checking the ref target</iso:title>
		<iso:p>All ref target Level Checks</iso:p>
		<iso:rule context="tei:ref[@type='pageref']">
			<iso:assert test="substring(@target,2)=//tei:pb/@xml:id[.]" role="Priority1" id="a21"
					>All pagerefs must point to existing pb xml:ids. <iso:value-of
					select="substring(@target,2)"/> does not exist.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check all page ref target against text -->
	<iso:pattern id="pageref.id.checks">
		<iso:title>Checking the page ref target</iso:title>
		<iso:p>All page ref target Level Checks</iso:p>
		<iso:rule context="//tei:ref[@type='pageref']">
			<iso:assert test="substring-after(@target,'pg')=current()" role="Priority1" id="a14"
					>All ref targets must match the actual page. <iso:value-of select="current()"
					/> does not match <iso:value-of select="substring-after(@target,'pg')"/>.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Variables to get full chap id prefix -->
	<iso:let name="chap-id" value="concat('uncp-',$isbn,'-c')"/>

	<!-- Output chapter xml:id -->
	<iso:pattern id="chapter.checks">
		<iso:title>Checking the chapter Structure</iso:title>
		<iso:p>All chapter Level Checks</iso:p>
		<iso:rule context="//tei:body/tei:div[@type='chapter']">
			<iso:assert test="starts-with(@xml:id,'c')" role="Priority1" id="a15"
					>The id of chapter divs should have the following structure: c{chapNo}: <iso:value-of
					select="@xml:id"/>.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Variables to get full bibItem id prefix -->
	<iso:let name="bib-id" value="concat('uncp-',$isbn,'-bibItem')"/>

	<!-- Output Bibliography bibItem xml:id -->
	<iso:pattern id="bibliography.checks">
		<iso:title>Checking the bibliography Structure</iso:title>
		<iso:p>All bibItem Level Checks</iso:p>
		<iso:rule context="//tei:div[@type='bibliography']//tei:bibl">
			<iso:assert test="(@xml:id)" role="Priority1" id="a16"
				>All bibliography items should have ids.</iso:assert>
			<iso:assert test="starts-with(@xml:id,'bibItem')" role="Priority1" id="a31"
					>The id of bibItems should have the following structure: bibItem{No}: <iso:value-of
					select="@xml:id"/>.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check that divs have heads, and type attribute -->
	<iso:pattern id="div.checks">
		<iso:title>Checking the div Structure</iso:title>
		<iso:p>All div Level Checks</iso:p>
		<iso:rule context="//tei:div">
			<iso:assert test="tei:head" role="Priority2" id="a17"
				>All divs generally have a head</iso:assert>
			<iso:assert test="(@type)" role="Priority1" id="a18"
				>All divs must have a type or type attribute</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check that div subsections are nested correctly -->
	<iso:pattern id="div_head.checks">
		<iso:title>Checking the div head Structure</iso:title>
		<iso:p>All div nested Level Checks</iso:p>
		<iso:rule context="//tei:div[@type='ahead']">
			<iso:assert
				test="ancestor::tei:div[@type='chapter']|ancestor::tei:div[@type='introduction']|ancestor::tei:div[@type='preface']|ancestor::tei:div[@type='conclusion']|ancestor::tei:div[@type='endnotes']|ancestor::tei:div[@type='bibliography']"
				role="Priority1" id="a19"
					>All ahead sections should be children of chapters: this div has a type of <iso:value-of
					select="ancestor::tei:div/@type"/>.</iso:assert>
		</iso:rule>
		<!-- add frontmatter context to allow for ahead sections -->
		<iso:rule context="//tei:div[@type='bhead']">
			<iso:assert test="parent::tei:div[@type='ahead']" role="Priority2" id="a20"
					>All bhead sections should be children of ahead divs: this div has a type of <iso:value-of
					select="parent::tei:div/@type"/>.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check that bibls in back are nested correctly in listbibl -->
	<iso:pattern id="bibl.checks">
		<iso:title>Checking the bibl Structure</iso:title>
		<iso:p>All bibl nested Level Checks</iso:p>
		<iso:rule context="/tei:TEI/tei:text/tei:back//tei:bibl">
			<iso:assert test="parent::tei:listBibl" role="Priority2" id="a66"
					>All bibl elements in back should be children of listBibl:: this bibl's parent is <iso:value-of
					select="parent::tei:listBibl"/>.</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- Check that heads have type attribute -->
	<iso:pattern id="head.checks">
		<iso:title>Checking the head Structure</iso:title>
		<iso:p>Checking head for @type</iso:p>
		<iso:rule context="//tei:head">
			<iso:assert test="(@type)" role="Priority2" id="a42"
				>All heads generally have a type attribute</iso:assert>
		</iso:rule>
	</iso:pattern>

	<!-- bibliography checks -->
	<iso:pattern id="bib.checks">
		<iso:title>Checking the bibliography Structure</iso:title>
		<iso:p>Checking title for @level</iso:p>
		<iso:rule context="	//tei:listBibl[@type='crossref']/tei:bibl//tei:title">
			<iso:assert test="(@level)" role="Priority1" id="a43"
				>All bibl titles require a level attribute</iso:assert>
		</iso:rule>
	</iso:pattern>




</iso:schema>
