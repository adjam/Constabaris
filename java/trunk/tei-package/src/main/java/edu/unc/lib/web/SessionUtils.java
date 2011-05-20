package edu.unc.lib.web;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * Utilities for working with attributes stored in the current HTTP session.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class SessionUtils {
	
	/**
	 * The name of a session-scoped attribute that holds the location of files
	 * uploaded during a specific session.
	 */
	public static final String SESSION_UPLOADS_ATTR = "upload.session.files";
	
	/**
	 * The name of a directory holding the files uploaded during a session.
	 */
	public static final String SESSION_LOCAL_DIRECTORY = "upload.session.files.directory";
	
	
	private SessionUtils() {}
	
	/**
	 * Gets an object by name from the current session (handles null sessions).
	 * @param attributeName
	 * @return the 
	 */
	public static Object getSessionAttribute(HttpServletRequest req, String attributeName) {
		HttpSession session = req.getSession(false);
		if ( session == null ) {
			return null;
		}
		return session.getAttribute(attributeName);
		
	}
	

}
