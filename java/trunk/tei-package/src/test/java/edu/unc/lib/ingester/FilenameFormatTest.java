package edu.unc.lib.ingester;

import static org.junit.Assert.*;

import java.util.HashMap;
import java.util.Map;

import org.junit.Test;

import edu.unc.lib.ingest.FilenameFormat;

public class FilenameFormatTest {
	
	FilenameFormat instance = new FilenameFormat("jingle", "bells");

	@Test
	public void testGetFilename() {
		String fn = instance.getFilename(0);
		assertEquals("jingle.bells", fn);
		fn = instance.getFilename(73);
		assertEquals("jingle-73.bells", fn);
	}

	@Test
	public void testGetSequenceOf() {
		Map<String,Integer> tests = new HashMap<String, Integer>();
		tests.put("jingle.bells", 0);
		tests.put("jingle-34.bells", 34);
		tests.put("jingle-2.bells", 2);
		for (Map.Entry<String,Integer> entry : tests.entrySet() ) {
			assertEquals( entry.getValue().intValue(), instance.getSequenceOf(entry.getKey()));
		}
	}
	
	@Test(expected = IllegalArgumentException.class ) 
	public void testGetSequenceOfBadInput() {
		instance.getSequenceOf("freaking-19.bells");
		
	}

	@Test
	public void testToString() {
		String ts = instance.toString();
		assertTrue( ts.contains("jingle") );
		assertTrue( ts.contains("bells"));
	}

}
