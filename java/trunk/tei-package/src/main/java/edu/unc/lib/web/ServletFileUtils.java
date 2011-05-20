package edu.unc.lib.web;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.IOUtils;

/**
 * Utilities for servlets interacting with the filesystem.
 * @author adamc
 */
public class ServletFileUtils {
	
	
	// prevent instantiation.
	private ServletFileUtils() {}
	
	/**
	 * Writes the contents of a specified file to the output response.
	 * <p>
	 *  Clients of this method are responsible for setting <code>ContentType</code> and 
	 *  <code>ContentEncoding</code> headers on the response before calling this
	 *  method, while <code>Content-Length</code> is handled by this method.
	 * </p>
	 * <p>
	 *  Callers may also specify that client browsers should prompt for a download of
	 *  the file sent, by having a non-null value for the <code>filename</code>
	 *  parameter.  If this parameter is not null, an additional header of the form
	 *  <code>Content-Disposition: attachment; filename=[filename param]</code> will
	 *  be sent along with the response.
	 * </p>
	 * @param inputFile the file to be written to the response.
	 * @param resp the response object.
	 * @param filename the filename to specify on the <code>Content-Disposition</code>
	 * header (tells browsers to 'save as' and suggests a name).  If <code>null</code>,
	 * no <code>Content-Disposition</code> header will be sent and the user's browser will
	 * determine how to handle the file.
	 * @throws IOException if there is an error reading the file or writing it to the response.
	 */
	public static void writeFileToResponse(File inputFile, HttpServletResponse resp, String filename) throws IOException {
		InputStream input = null; 
		OutputStream output = null;
		try {
			input = new FileInputStream(inputFile);
			resp.setContentLength((int)inputFile.length());
			if ( filename != null ) {
				resp.addHeader("Content-Disposition", "attachment; filename=" + filename);
			}
			output = resp.getOutputStream();
			IOUtils.copy( input, output);
		} finally {
			IOUtils.closeQuietly(input);
			IOUtils.closeQuietly(output);
		}
	}
}
