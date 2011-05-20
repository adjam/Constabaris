package edu.unc.lib.web.servlets;
import java.io.IOException;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



public class LogoutServlet extends HttpServlet {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private static final Logger logger = LoggerFactory.getLogger(LogoutServlet.class);
	
	@Override
	public void init(ServletConfig config) {
		logger.info("Initializing {}", config.getServletName());
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		HttpSession sess = req.getSession(false);
		if (sess != null ) {
			logger.debug("Ending Session");
			sess.invalidate();
		}
		if ( logger.isTraceEnabled() ) {
			logger.debug("Redirecting to {}", req.getContextPath() );
		}
		RequestDispatcher d = req.getRequestDispatcher("/logout.jsp");
		d.forward(req, resp);
	}


}
