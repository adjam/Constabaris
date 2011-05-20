package edu.unc.lib.ingest;

import java.util.regex.Matcher;
import java.util.regex.Pattern;


/**
 * Helper class to help parse XHTML file output names; specifically helps with extracting the order of the
 * XHTML file in the generated sequence, based on the file's name.
 * @author adamc
 *
 */
public class FilenameFormat {
	
	private String prefix;
	
	private String extension;
	
	private Pattern seqPattern;

	public FilenameFormat(String prefix, String extension) {
		this.prefix = prefix;
		this.extension = extension;
		seqPattern = Pattern.compile("^" + prefix + "(?:-(\\d+))?\\." + extension);
	}
	
	public String getFilename(int sequence) {
		if ( sequence > 0 ) {
			return prefix + "-" + sequence + "." + extension;
		}
		return prefix + "." + extension;
	}
	
	public int getSequenceOf(String inputFile) {
		Matcher m = seqPattern.matcher(inputFile);
		if ( m.matches() ) {
			if ( m.group(1) == null ) {
				return 0;
			}
			return Integer.parseInt(m.group(1));
		}
		String msg = String.format("Input file '%s' does not match prefix '%s' and and extension '%s'", inputFile, prefix, extension );
		throw new IllegalArgumentException(msg);
	}
	
	public String toString() {
		return "FilenameFormat('" + prefix + "','" + extension + "')";
	}

}
