package edu.unc.lib.web.servlets;

import java.io.File;
import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.web.listeners.UploadContextListener;

/**
 * This servlet handles requests to remove old files from the application's
 * working directory.  Note that you need to POST the correct key (found in this file) in order
 * to effect. the cleanup.
 * @author adamc, $LastChangedBy$
 * $Id$
 **/
public class CleanupServlet extends DispatcherServlet {

    private static final Logger logger = LoggerFactory.getLogger(CleanupServlet.class);
    private static final String DEFAULT_PW = "speaktomenotofgenehackman";
    private String password = DEFAULT_PW;
    /**
     *
     */
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String key = req.getParameter("authz");

        logger.info("Cleanup requested");
        for (Object parm : req.getParameterMap().keySet()) {
            logger.info(String.format("<%s> parameter: '%s'%n", parm, req.getParameter(parm.toString())));
        }

        if (password != null || !password.equals(key)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "No dice.");
            return;
        }
        String basePath = getApplicationConfig().getVariable(UploadContextListener.BASE_UPLOAD_DIRECTORY);
        File baseDir = new File(basePath); 
        FileUtils.cleanDirectory(baseDir);
        resp.setContentType("text/plain");
        resp.getWriter().write("That's all that done with, then");
    }

    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        setPassword(config);
    }

    @Override
    public void init() throws ServletException {
        super.init();
        setPassword(getServletConfig());
    }

    private void setPassword(ServletConfig config) {
        String pw = config.getInitParameter("password");
        if (pw != null) {
            password = pw;
        }
    }

	@Override
	public String getDefaultDispatchURL() {
		// don't need this, just wanted the 'getApplicationConfig' utility method
		return null;
	}
}
