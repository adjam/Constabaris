package edu.unc.lib.web.servlets;

import java.io.IOException;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.web.ApplicationConfig;


/**
 * Base class for servlets that perform some processing and then delegate to another URL to handle requests.
 * @author adamc
 *
 */
public abstract class DispatcherServlet extends HttpServlet {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private static final Logger logger = LoggerFactory.getLogger(DispatcherServlet.class);
	
	private String dispatchURL;
	
	protected String getDispatchURL() {
		return this.dispatchURL;
	}
	
	@Override
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		this.dispatchURL = config.getInitParameter("dispatchUrl");
		if ( dispatchURL == null ) {
			dispatchURL = getDefaultDispatchURL();
		}
		logger.info("Servlet '{}' will dispatch to {}", config.getServletName(), dispatchURL);
	}
	
	/**
	 * Subclasses will need to override this in order to provide a URL to use if
	 * one is not explicitly configured as the <code>dispatchUrl</code> initialization
	 * parameter in <code>web.xml</code>.
	 * @return
	 */
	public abstract String getDefaultDispatchURL();
	
	
	public ApplicationConfig getApplicationConfig() {
		return (ApplicationConfig)getServletContext().getAttribute(ApplicationConfig.ATTRIBUTE_NAME);
	}

	
	
	
	public void handleDispatch(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		RequestDispatcher d = req.getRequestDispatcher(getDispatchURL());
		d.forward(req,resp);
	}

}
