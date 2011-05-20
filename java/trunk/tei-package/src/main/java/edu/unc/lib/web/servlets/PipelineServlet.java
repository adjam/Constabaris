package edu.unc.lib.web.servlets;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.MessageDigest;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.data.URLTester;
import edu.unc.lib.data.UploadEvent;
import edu.unc.lib.data.UploadSession;
import edu.unc.lib.ingest.IngestFileUtils;
import edu.unc.lib.web.ApplicationConfig;
import edu.unc.lib.web.ServletFileUtils;
import edu.unc.lib.web.SessionFilter;
import edu.unc.lib.web.SessionUtils;
import edu.unc.lib.web.action.IngestHandler;
import edu.unc.lib.web.action.UploadHandler;
import edu.unc.lib.web.listeners.UploadContextListener;
import edu.unc.lib.xproc.PipelineFailureException;
import edu.unc.lib.xproc.PipelineRunner;

public class PipelineServlet extends DispatcherServlet {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	private static final Logger logger = LoggerFactory.getLogger(PipelineServlet.class);

	private String[] _assetLocations;

	private URL xprocURL;

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		if ( logger.isTraceEnabled() ) {
			logger.trace("doPost({}, {})", req.getContentType(), req.getContentLength());
		}
		File outputDirectory = SessionFilter.sessionDirectory.get();
		
		boolean hasSession = outputDirectory != null;

		if ( !hasSession ) { // this will be true if the sessionfilter is not invoked,
			outputDirectory = IngestFileUtils.createTempDir(true);
		}
		UploadHandler handler = new UploadHandler(outputDirectory);
		if ( "true".equals(req.getParameter("reload")) ) {
			clearXProcURL();
		}
		File uploadedFile = handler.doPost(req);
		File pipelineOutput = null;
		try {
			pipelineOutput = runPipeline(uploadedFile, outputDirectory);
		} catch (PipelineFailureException e) {
			throw new ServletException(e);
		}
		if ( handler.isMultipart() ) {
			UploadSession uploadSession = (UploadSession)SessionUtils.getSessionAttribute(req, SessionFilter.UPLOAD_SESSION);
			UploadEvent evt = createUploadEvent(req, pipelineOutput, uploadedFile, handler.getChecksum(), handler.getFileName(), handler.getMimeType(), handler.getEncoding());
			if ( uploadSession != null ) {
				logger.trace("Adding uploadEvent to the session");
				uploadSession.addEvent(evt);
			}
			// 	for the jSP
			req.setAttribute("uploadEvent", evt);
			handleDispatch(req, resp);
			return;
		}
		
		resp.setContentType("application/zip");
		String filename = "ingest-package.zip";
		ServletFileUtils.writeFileToResponse(pipelineOutput, resp, filename);
		if ( !hasSession) {
			FileUtils.deleteDirectory(outputDirectory);
		}
	}
	
	
	@Override
	protected void doPut(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		File uploadDirectory = (File)getServletContext().getAttribute( UploadContextListener.BASE_UPLOAD_DIRECTORY );
		UploadHandler handler = new UploadHandler(uploadDirectory);
		File destination = handler.getEntityAsFile(req);
		File outputDirectory = null;
		try {
			outputDirectory = IngestFileUtils.createTempDir(true);
			File pipelineOutput = runPipeline(destination, outputDirectory);
			resp.setContentType("application/zip");
			String filename = "ingest-package.zip";
			ServletFileUtils.writeFileToResponse(pipelineOutput,resp, filename);
		} catch( PipelineFailureException pfx) {
			throw new ServletException(pfx);
		} finally {
			FileUtils.deleteDirectory(outputDirectory);
		}
	}

	@Override
	public String getDefaultDispatchURL() {
		return "/upload.jsp";
	}
	
	private synchronized void clearXProcURL() {
		this.xprocURL = null;
	}
	
	
	private boolean urlExists(URL url) {
		URLTester tester = new URLTester();
		boolean exists = tester.testURLResolves(url);
		tester.close();
		return exists;
	}
	
	private String [] getAssetLocations() {
		if ( _assetLocations == null ) {
			_assetLocations = getApplicationConfig().getAssetLocationString().split(",");
		}
		return _assetLocations;
	}
	
	private URL findXProc() {
		for( String loc : getAssetLocations() ) {
			logger.debug("Checking location: " + loc);
			if ( loc.startsWith("http:") || loc.startsWith("https:") ) {
				try {
					URL rv = new URL(loc);
					if (urlExists(rv) ) {
						logger.debug("Using xproc at " + rv);
						return rv;
					}
				} catch( MalformedURLException mux ) {
					logger.trace("Unable to find XProc script at " + loc);
				}
				continue;
			}
				
			File locFile = new File(loc);
			
			if ( locFile.isDirectory() ) {
				locFile = new File(locFile, "xpl/ingest.xpl");
			}
			
			if ( locFile.exists() ) {
				try {
					logger.debug("Found file at " + locFile.getAbsolutePath() );
					return locFile.toURI().toURL();
				} catch( MalformedURLException mux ) {
					logger.error("Wow, unable to create a file:/// URL", mux);
					throw new RuntimeException("Unable to load files ...?");
				}
			} else {
				logger.debug("Could not find XProc at " + locFile.getAbsolutePath() );
			}
		}
		logger.debug("XProc will be loaded from classpath");
		return getClass().getResource("/xpl/ingest.xpl");
	}
	
	private URL getXProcURL() {
		if ( this.xprocURL == null ) {
			this.xprocURL = findXProc();
		}
		return this.xprocURL;
	}
	
	private File runPipeline(File input, File outputBase) throws IOException, PipelineFailureException {
		if ( logger.isDebugEnabled() ) {
			logger.debug("Starting pipeline on {}", input.getAbsolutePath() );
		}
		
		try {
			File outputDirectory = IngestFileUtils.createTempDir(outputBase, false);
			URL xprocURL = getXProcURL();
			PipelineRunner runner = new PipelineRunner(xprocURL);
			File output = new File(input.getParentFile(), "ingest.zip");
			logger.debug("starting ingest handler");
			IngestHandler handler = new IngestHandler(runner, input, outputDirectory);
			handler.setOutputFile( output );
			handler.execute();
			return output;
		} catch( IOException iox ) {
			logger.error("Error encountered running pipeline", iox);
			throw iox;
		} catch( PipelineFailureException pfx ) {
			logger.error("Error encountered during pipeline execution", pfx);
			throw pfx;
		}
	}
	
	private UploadEvent createUploadEvent(HttpServletRequest req, File resultFile, File uploadedFile, MessageDigest checksum, String fileName, String mimeType, String encoding) {
		return new UploadEvent(fileName, uploadedFile,resultFile, mimeType, encoding, System.currentTimeMillis(),checksum);
	}
	
	@Override
	public void init(ServletConfig config) throws ServletException {
		logger.trace("Initializing PipelineServlet");
		super.init(config);
		ApplicationConfig appConfig = getApplicationConfig();
		appConfig.addPropertyChangeListener(UploadContextListener.XPROC_LOCATIONS, 
				new PropertyChangeListener() {

					@Override
					public void propertyChange(PropertyChangeEvent evt) {
						logger.debug("XPRoc location changed, {} to {}", evt.getOldValue(), evt.getNewValue());
						synchronized(PipelineServlet.this) {
							PipelineServlet.this.clearXProcURL();
							PipelineServlet.this._assetLocations = null;
						}
					}
			
		});
		String assetLocationString = getApplicationConfig().getVariable(UploadContextListener.XPROC_LOCATIONS);
		if ( assetLocationString == null ) {
			return;
		}
		
	}
	
	
	
	
}
	
