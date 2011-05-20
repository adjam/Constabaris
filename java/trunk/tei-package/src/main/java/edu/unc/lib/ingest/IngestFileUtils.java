package edu.unc.lib.ingest;

import java.io.File;
import java.io.IOException;

import org.apache.commons.io.FileCleaningTracker;
import org.apache.commons.io.FileDeleteStrategy;

/**
 * Tools for creating and deleting files as part of the ingest process.
 * @author adamc, $LastChangedBy$
 *
 */
public class IngestFileUtils {
	
	
	private static final FileCleaningTracker tracker = new FileCleaningTracker();
	
	static {
		Runtime.getRuntime().addShutdownHook( new Thread() {
			public void run() {
				tracker.exitWhenFinished();
			}
		});
	}
	
	/**
	 * Creates a temporary directory in the VM's temp dir (i.e. <code>java.io.tmpdir</code>).
	 * @param deleteOnExit whether the directory should be deleted on exit.
	 * @return a File object pointing at the new directory.
	 * @throws IOException if the directory cannot be created.
	 */
	public static File createTempDir(boolean deleteOnExit) throws IOException {
		return createTempDir(null, deleteOnExit);
	}
	
	/**
	 * Creates a temporary directory underneath a specified directory.
	 * @param baseDir the parent of the newly created directory; if <code>null</code>,
	 * uses JDK standard tempfile creation routine.
	 * @param deleteOnExit whether the directory should be deleted on exit.
	 * @return a File object pointing at the new directory.
	 * @throws IOException if the directory cannot be created.
	 */
	public static File createTempDir(File baseDir, boolean deleteOnExit) throws IOException {
		String prefix = "dir-";
		String suffix = "-tmp";
		File temp;
		do {
			if ( baseDir == null ) {
				temp = File.createTempFile(prefix,suffix);
			} else {
				temp = File.createTempFile(prefix, suffix, baseDir);
			}
			temp.delete();
		} while( !temp.mkdir() );
		if ( deleteOnExit ) {
			tracker.track(temp, temp, FileDeleteStrategy.FORCE);
			temp.deleteOnExit();
		}
		return temp;
	}

	/**
	 * Gets a human-readable file size.
	 * @param input the file whose size is to be measured.
	 * @return a string of the form "####.#MB"
	 */
	public static String formatFileSize(File input) {
		if ( input == null || !input.exists() ) {
			return "[none]";
		}
		long size = input == null ? 0 : input.length();
		float mbSize = (float) ( size / ( 1024.0f * 1024.0f ));
		return String.format("%.1fMB", mbSize);
	}
	
	/**
	 * Ensures that all the parents of a specific path exists, i.e. an equivalent of the shell command 
	 * <code>mkdir -p</code>.
	 * @param outputPath the path to a file.
	 * @throws IOException if the path cannot be created.
	 */
	public static void ensureParentExists(File outputPath) throws IOException {
		File directory = outputPath.getParentFile();
		if (!directory.exists()) {
			if ( directory.mkdirs() ) {
				return;
			} 
			throw new IllegalArgumentException("Unable to create " + directory.getAbsolutePath() + " (reason: uknown)");
		}
	}
}
