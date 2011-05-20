package edu.unc.lib.web.servlets;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.data.UploadEvent;
import edu.unc.lib.data.UploadSession;
import edu.unc.lib.web.SessionFilter;

public class SessionFilesServlet extends DispatcherServlet {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private static final Logger logger = LoggerFactory.getLogger(SessionFilesServlet.class);

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		HttpSession session = req.getSession(false);
		if ( session != null ) {
			UploadSession uSess;
			if ( ( uSess = (UploadSession)session.getAttribute(SessionFilter.UPLOAD_SESSION) ) != null ) {
				req.setAttribute("uploadSession", uSess);
				String pathInfo = req.getPathInfo();
				logger.info("Path info: {}", pathInfo);
				if ( "/".equals(pathInfo) || pathInfo == null ) {
					logger.trace("Hi there, just handling a simple get!");
					handleDispatch(req, resp);
					return;
				} else {
					// pathInfo => /[uuid]/original filename
					String [] parts = pathInfo.substring(1).split("/");
					assert( parts.length == 2);
					String uuid = parts[0];
					String fileName = parts[1];
					logger.info("Locating event with UUID {} and filename {}", uuid, fileName);
					UploadEvent evt = uSess.getById(uuid);
					if ( evt == null ) {
						logger.error(uSess.getSessionAsString());
						resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Unable to find that upload");
						return;
					}
					getContents(req, resp, evt);
				}
			}
		} else {
			resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "We're unable to locate your current session, and so we can't find the files you've been working on.");
		}
	}
	
	public void getContents(HttpServletRequest req, HttpServletResponse resp, UploadEvent event) throws IOException {
		File source = null;
		if ( req.getParameter("original") != null ) {
			source = event.getUploadedFile();
		} else {
			source = event.getResultFile();
		}
		
		String mimeType = event.getMimeType();
		InputStream input = null; 
		OutputStream output = null;
		try {
			input = new FileInputStream(source);
			output = resp.getOutputStream();
			resp.setContentType(mimeType);
			resp.setCharacterEncoding(event.getEncoding());
			resp.setContentLength((int)source.length());
			IOUtils.copy( input, output);
		} finally {
			IOUtils.closeQuietly(input);
			IOUtils.closeQuietly(output);
		}
			
	}

	@Override
	public String getDefaultDispatchURL() {
		return "/session.jsp";
	}

}
