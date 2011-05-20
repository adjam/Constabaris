package edu.unc.lib.web;

import java.io.File;
import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import edu.unc.lib.data.UploadSession;

/**
 * Servlet filter that helps maintain session  state for interactive use of the ingest services.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 *
 */
public class SessionFilter implements Filter {
	
	
	public static final String UPLOAD_SESSION = SessionFilter.class.getName() + ".session";

	public static ThreadLocal<File> sessionDirectory = new ThreadLocal<File>();

	public void destroy() {
		// TODO Auto-generated method stub

	}

	public void doFilter(ServletRequest req, ServletResponse resp,
			FilterChain chain) throws IOException, ServletException {
		// make sure a session is created
		HttpSession session = null;
		if ( req instanceof HttpServletRequest ) {
			session = ((HttpServletRequest)req).getSession(true);
			File sessionDir = ((UploadSession)session.getAttribute(UPLOAD_SESSION)).getOutputDirectory();
			sessionDirectory.set(sessionDir);
		}
		try {
			chain.doFilter(req, resp);
		} finally {
			sessionDirectory.set(null);
		}
	}

	public void init(FilterConfig arg0) throws ServletException {
		// nop

	}

}
