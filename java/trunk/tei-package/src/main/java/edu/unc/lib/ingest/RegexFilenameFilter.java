package edu.unc.lib.ingest;

import java.io.File;
import java.io.FilenameFilter;
import java.util.regex.Pattern;

public class RegexFilenameFilter implements FilenameFilter {
	
	public static final String SEGMENT_HTML_PATTERN = "^\\d+-segment.html";
	
	private Pattern filenamePattern;
	
	public RegexFilenameFilter(String pattern) {
		filenamePattern = Pattern.compile(pattern);
	}

	public boolean accept(File dir, String name) {
		return filenamePattern.matcher(name).matches();
	}

}
