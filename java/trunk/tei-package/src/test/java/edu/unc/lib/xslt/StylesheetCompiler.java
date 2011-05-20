package edu.unc.lib.xslt;


import static org.junit.Assert.*;

import java.net.URL;

import javax.xml.transform.stream.StreamSource;

import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.XsltCompiler;

import org.junit.Test;

/**
 * Unit test that checks to see whether the master stylesheet <code>/xsl/driver.xsl</code>
 * can be compiled, to provide a sanity check before execution.
 **/
public class StylesheetCompiler {

        public static final String DEFAULT = "/xsl/driver.xsl";
	
	@Test
	public void testCompileStylesheet() {
		URL url = getClass().getResource(DEFAULT);
		assertNotNull(url);
		Processor p = new Processor(false);
		XsltCompiler comp = p.newXsltCompiler();
		try {
		comp.compile( new StreamSource(url.openStream(), url.toString() ) );
		assertTrue(true);
		} catch( Exception e ) {
			fail(e.getMessage());
		}
	}
	
	@Test
	public void testCompileTEI2MetsStylesheet() {
		URL url = getClass().getResource("/xsl/tei2mets.xsl");
		assertNotNull(url);
		Processor p = new Processor(false);
		XsltCompiler comp = p.newXsltCompiler();
		try {
		comp.compile( new StreamSource(url.openStream(), url.toString() ) );
		assertTrue(true);
		} catch( Exception e ) {
			fail(e.getMessage());
		}
	}

}
