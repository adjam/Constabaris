package edu.unc.lib.archive;

import static org.junit.Assert.*;

import java.io.File;
import java.io.IOException;
import java.util.List;

import org.junit.Test;

import edu.unc.lib.ingest.IngestFileUtils;

public class DirectoryArchiverTest {

	@Test
	public void testGetArchive() throws Exception {
		File tmpDir = IngestFileUtils.createTempDir(true);
		File tmpFile = File.createTempFile("touched-", ".tmp", tmpDir);
		tmpFile.deleteOnExit();
		File zip = null;
		try {
			DirectoryArchiver arch = new DirectoryArchiver();
			zip = arch.getArchive(tmpDir);
			assertTrue(zip.exists());
		} finally {
			if ( zip != null ) {
				zip.delete();
			}
		}
		
	}

	@Test
	public void testGetPackageFiles() {
		File f = new File("/tmp/calabash-output");
		if ( !f.exists() ) {
			assertTrue("Unable to create directory!", f.mkdir() );
		}
		
		DirectoryArchiver arch = new DirectoryArchiver();
		try {
			File temp = File.createTempFile("things", "thangs", f);
			temp.deleteOnExit();
			
			List<File> packaged = arch.getPackageFiles(f);
			assertNotNull(packaged);
			assertTrue(packaged.size() > 0);
		} catch( IOException iox ) {
			fail("Encountered IOException:" + iox.getMessage());
		}
		
	}

}
