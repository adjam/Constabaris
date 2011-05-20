package edu.unc.lib.web.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ErrorServlet extends HttpServlet {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private Logger logger = LoggerFactory.getLogger(ErrorServlet.class);
	
	@Override
	protected void service(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		Throwable error = (Throwable)req.getAttribute("javax.servlet.error.exception");
		if ( error == null ) {
			resp.sendRedirect( req.getContextPath() );
			return;
		}
		StringWriter sw = new StringWriter();
		PrintWriter pw = new PrintWriter(sw);
		error.printStackTrace(pw);
		pw.close();
		req.setAttribute("stackTrace", sw.toString());
		logHeaders(req, error);
		req.getRequestDispatcher("/error.jsp").forward(req,resp);
	}
	
	
	private void logHeaders(HttpServletRequest req, Throwable error) {
		logger.error("Error serving URI {} to {}", req.getRequestURI(), req.getRemoteAddr() );
		logger.error("Throwable: ", error);
	}


}
