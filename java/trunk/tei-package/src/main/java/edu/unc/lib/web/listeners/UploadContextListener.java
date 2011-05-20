package edu.unc.lib.web.listeners;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.data.UploadSession;
import edu.unc.lib.ingest.IngestFileUtils;
import edu.unc.lib.web.ApplicationConfig;
import edu.unc.lib.web.SessionFilter;

/**
 * Multipurpose listener for servlet container events to enable handling of uploads.
 * @author adamc
 */
public class UploadContextListener implements ServletContextListener, HttpSessionListener {

	private static final Logger logger = LoggerFactory.getLogger(UploadContextListener.class);
	
	public static final String BASE_UPLOAD_DIRECTORY = UploadContextListener.class.getName() + ".uploads";
	
	public static final String XPROC_LOCATIONS = UploadContextListener.class.getName() + ".xproc";
	
	private File baseUploadDir = null;
	
	/**
	 * Handles the close of the context (webapp shutdown).
	 * @param evt the context closing event.
	 */
	public void contextDestroyed(ServletContextEvent evt) {
		if ( baseUploadDir != null ) {
			logger.info("Cleaning up uploads directory");
			try {
				FileUtils.cleanDirectory(baseUploadDir);
			} catch( IOException ioe ) {
				logger.warn("Unable to clean upload directory", ioe);
			}
		}
	}

	/**
	 * Locates and creates (if necessary) the base directory where uploads will be stored.  
	 * Uses the value specified by the <code>baseUploadDir</code> context parameter, or <code>pipeline-uploads</code>
	 * in the directory specified by the the value of the <code>java.io.tmpdir</code> system property.
	 * @param evt the context initialization event.
	 * @throws ExceptionInInitializerError if the base upload directory does not exist and cannot be
	 * created.  
	 */
	public void contextInitialized(ServletContextEvent evt) {
		ServletContext ctx = evt.getServletContext();
		ApplicationConfig config = new ApplicationConfig();
		
		String baseUploadPath = ctx.getInitParameter("baseUploadDir");
		
		if ( baseUploadPath != null ) {
			logger.info("Initializing working directories from web.xml config to {}", baseUploadPath);
			baseUploadDir = new File(baseUploadPath);
		} else {
			File contextTemp = (File)evt.getServletContext().getAttribute("javax.servlet.context.tempdir");
			logger.info("Initializing working directories from servlet context temp dir: {}({})", contextTemp.getAbsolutePath(), contextTemp.isDirectory() ? "+" : "-");
			baseUploadDir = new File(contextTemp, "pipeline-uploads");
		}
		ensureUploadDirectoryExists(baseUploadDir);
		ctx.setAttribute(ApplicationConfig.ATTRIBUTE_NAME, config);
		
		ctx.setAttribute(BASE_UPLOAD_DIRECTORY, baseUploadDir);
		config.setVariable(BASE_UPLOAD_DIRECTORY, baseUploadDir.getAbsolutePath());
		config.setVariable(XPROC_LOCATIONS, loadAssets(ctx));
	}

	public void sessionCreated(HttpSessionEvent evt) {
		if ( logger.isTraceEnabled() ) {
			logger.trace("Initializing session {}", evt.getSession().getId() );
		}
		try {
			File sessionDir = IngestFileUtils.createTempDir(baseUploadDir,false);
			logger.info("Creating new session with working directory in {}", sessionDir.getAbsolutePath());
			HttpSession session = evt.getSession();
			session.setAttribute(SessionFilter.UPLOAD_SESSION, new UploadSession(sessionDir));
		} catch( IOException iox ) {
			logger.error("Unable to create file directory for session", iox);
		}
	}

	public void sessionDestroyed(HttpSessionEvent evt) {
		UploadSession session = (UploadSession)evt.getSession().getAttribute(SessionFilter.UPLOAD_SESSION);
		if ( session != null ) {
			File summary = new File(session.getOutputDirectory(), "session-summary.txt");
			String data = session.getSessionAsString();
			try {
				FileUtils.writeStringToFile(summary, data);
			} catch( IOException iox ) {
				String msg = String.format("Unable to write session summary to %s", summary.getAbsolutePath());
				logger.warn(msg, iox);
			}
		}
	}
	
	private void ensureUploadDirectoryExists(File uploadDirectory) {
		if (!uploadDirectory.isDirectory() ) {
			logger.info("{} is not a directory, creating ...", baseUploadDir.getAbsolutePath() );
			boolean created = uploadDirectory.mkdirs();
			if ( !created ) {
				throw new ExceptionInInitializerError("Unable to initialize upload directory " + baseUploadDir.getAbsolutePath() );
			}
		}
		copyReadme(uploadDirectory);
	}
	
	/**
	 * Copies a README file from the .jar to the upload directory so
	 * system administrators will know what is going on.
	 * @param uploadDirectory
	 */
	private void copyReadme(File uploadDirectory) {
		File readme = new File(uploadDirectory, "README");
		if ( readme.exists() ) {
			/// is it right?  Dunno, but let's leave it.
			return;
		}
		InputStream input = null;
		OutputStream output = null;
		try {
			input = getClass().getResourceAsStream("/README");
			output = new FileOutputStream(readme);
			IOUtils.copy(input,output);
		} catch( IOException ioe ) {
			logger.warn("Unable to copy README file to upload directory.", ioe);
		} finally {
			IOUtils.closeQuietly(input);
			IOUtils.closeQuietly(output);
		}
	}
	
	private String loadAssets(ServletContext ctx) {
		String jndiPath = "assets/XProc";
		logger.trace("loadAssets()");
		try {
			Context initCtx = new InitialContext();
			Context envContext = (Context)initCtx.lookup("java:comp/env");
			logger.trace("Querying JNDI for assets/XProc locations");
			String assetLocation = (String)envContext.lookup(jndiPath);
			logger.info("External stylesheet/XProc search locations: {}", assetLocation );
			return assetLocation;
						
		} catch( Exception ex ) {
			String msg = String.format("Unable to find XProc asset locations in JNDI at %s", jndiPath);
			logger.error(msg, ex);
			return null;
		}
	}

}
