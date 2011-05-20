package edu.unc.lib.xproc;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmNode;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xmlcalabash.core.XProcRuntime;
import com.xmlcalabash.io.ReadablePipe;
import com.xmlcalabash.runtime.XPipeline;

import edu.unc.lib.ingest.XdmHelper;

/**
 * PipelineResultHandler that sends documents on a pipeline's output ports to the filesystem.
 * 
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class DefaultPipelineResultHandler implements PipelineResultHandler {
	
	private static final Logger logger = LoggerFactory.getLogger(DefaultPipelineResultHandler.class);
	
	private final XProcRuntime runtime;
	
	private final XPipeline pipeline;

	private File outputDirectory;
	
	/**
	 * Creates a new instance with a specified runtime and pipeline object.
	 * @param runtime the XProc instance within which the pipeline was executed.
	 * @param pipeline the pipeline whose output is to be sent to the filesystem.
	 */
	public DefaultPipelineResultHandler(XProcRuntime runtime, XPipeline pipeline) {
		this.runtime = runtime;
		this.pipeline = pipeline;
	}
	
	/**
	 * Sets the directory to which all output will be sent.
	 * @param outputDirectory the directory to which content on the pipeline's output port will be sent.
	 */
	public void setOutputDirectory(File outputDirectory) {
		if ( !outputDirectory.isDirectory() ) {
			throw new IllegalArgumentException("Output directory must be an already-existing directory");
		}
		this.outputDirectory = outputDirectory;
	}
	
	/**
	 * Processes the pipeline's output ports.
	 * @throws RuntimeException if anything it doesn't know how to handle goes wrong.
	 * FIXME: Yes, this is bad practice.
	 */
	public void handleOutputs() {
		logger.trace("entering");
		Map<String,List<String>> results = new HashMap<String,List<String>>();
		Set<String> outputs = pipeline.getOutputs();
		OutputRedirector redirector = new OutputRedirector(runtime.getProcessor(), outputDirectory);
		try {
			redirector.clearOutputDirectory();
		} catch( IOException iox ) {
			throw new RuntimeException("Unable to clear output directory", iox);
		}
		for( String output : outputs ) {
			int portCount = 0;
			if ( logger.isDebugEnabled() ) {
				logger.debug("Reading output port '{}'", output);
			}
			List<String> resultStrings = new ArrayList<String>();
			ReadablePipe pipe = pipeline.readFrom(output);
			
			while( pipe.moreDocuments() ) {
				portCount++;
				if ( logger.isDebugEnabled() ) {
					logger.debug("Processing document {} on port {}", portCount, output);
				}
				try {
					XdmNode node = pipe.read();
					String rootNs = XdmHelper.getRootNodeNamespace(node);
					logger.debug("Storing result with base URI '{}' and namespace '{}' to file", node.getBaseURI(), rootNs );
					if ( node.getBaseURI() != null ) {
						redirector.storeNode(node, rootNs);
					}
					resultStrings.add(node.toString());
				} catch (SaxonApiException e) {
					throw new RuntimeException(e);
				} catch (IOException ioe ) {
					throw new RuntimeException(ioe);
				}
				results.put(output, resultStrings);
			}
		}
	}

	/**
	 * Deletes all the files in this handler's output directory.
	 */
	public void cleanup() {
		File tmpDir = new File( System.getProperty("java.io.tmpdir") );
		if ( outputDirectory != null && ! outputDirectory.equals( tmpDir ) ) {
			FileUtils.deleteQuietly( outputDirectory );
		}
	}

}
