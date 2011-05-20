package edu.unc.lib.xproc;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmNode;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.ingest.FilenameFormat;
import edu.unc.lib.ingest.IngestFileUtils;
import edu.unc.lib.ingest.XdmHelper;
import edu.unc.lib.ingest.Constants;

/**
 * Handles serialization of <code>XdmNode</code> output from Calabash to a specific directory.
 * @author adamc
 */
public class OutputRedirector {
	
	public static final String HTML_OUTPUT_PREFIX = "content/";
	
	public static final String HTML_PATTERN = "^\\d+-segment.html$";
	
	public static final String HTML_FILENAME_FORMAT = "%03d-segment.html";
	
	private File outputDirectory;
	
	private Processor processor;
	
	
	
	private Map<String,List<File>> outputFiles = new HashMap<String,List<File>>();
	
	private static final Logger logger = LoggerFactory.getLogger(OutputRedirector.class);
	
	/**
	 * Creates a new output redirector with a specified output directory.
	 * @param processor a Saxon Processor instance.
	 * @param outputDirectory the directory to which all output should be sent.
	 */
	public OutputRedirector(Processor processor, File outputDirectory) {
		this.processor = processor;
		if ( outputDirectory.exists() && !outputDirectory.isDirectory() ) {
			String msg = String.format("outputDirectory points to an existing file (%s) that is not a directory", outputDirectory.getAbsolutePath());
			throw new IllegalArgumentException(msg);
		}
		if ( !outputDirectory.exists() ) {
			outputDirectory.mkdir();
		}
		this.outputDirectory = outputDirectory;
	}
	
	public void clearOutputDirectory() throws IOException {
		FileUtils.cleanDirectory(outputDirectory);
	}
	
	public File getOutputDirectory() {
		return this.outputDirectory;
	}
	
	/**
	 * Stores a node to the file system, based on the baseURI of the node.
	 * @param node the node to be stored.
	 * @param rootNs the (possibly <code>null</code>) namespace URI of the node.  If <code>node</code> does not have a useful
	 * baseURI property (e.g. we are processing the primary output port), the output filename will be generated based on this value.
	 * @throws SaxonApiException if an error is encountered serializing the node.
	 * @throws IOException
	 */
	public void storeNode(XdmNode node, String rootNs) throws SaxonApiException, IOException {
		String ns = rootNs == null ? "" : rootNs;
		URI baseURI = node.getBaseURI();
		File outputFile = null;
		if ( baseURI == null || baseURI.toString().length() == 0) {
			outputFile = getNextFile(ns);
		} else {
			String fileName = new File(baseURI.getPath()).getName();
			if ( fileName == null || fileName.length() == 0 ) {
				fileName="default.xml";
			} else if ( fileName.endsWith(".html") ) {
				fileName = HTML_OUTPUT_PREFIX + fileName;
			}	
			outputFile = new File(outputDirectory, fileName);
			IngestFileUtils.ensureParentExists(outputFile);
		}
		if ( logger.isDebugEnabled() ) {
			logger.debug("Generating output for '{}' in {} ", baseURI, outputFile.getAbsolutePath());
		}
		XdmHelper.serializeToFile(node,processor, outputFile);
	}
	
	/**
	 * Gets the next available output filename for a document whose root node has the specified
	 * namespace URI.
	 * @param rootNamespace the namespace URI of the node to be serialized.
	 * @return a file in the <code>outputDirectory</code> that should not collide with already-serialized
	 * files.
	 */
	public File getNextFile(String rootNamespace) {
		int nextNum = 0;
		List<File> nsFiles = outputFiles.get(rootNamespace);
		if ( nsFiles == null ) {
			nsFiles = new ArrayList<File>();
			outputFiles.put(rootNamespace,nsFiles);
		}
		FilenameFormat fmt = getFormatForNamespace(rootNamespace);
		if ( nsFiles.size() > 0 ) {
			String lastName = nsFiles.get(nsFiles.size()-1).getName();
			nextNum = fmt.getSequenceOf(lastName)+1;
		}
		return new File(outputDirectory, fmt.getFilename(nextNum));
	}
	
	private FilenameFormat getFormatForNamespace(String ns) {
		if ( Constants.METS.equals(ns) ) {
			return new FilenameFormat("mets", "xml");
		} else if ( Constants.XHTML.equals(ns) ) {
			return new FilenameFormat("output", "html");
		} else if ( Constants.TEI.equals(ns) ) {
			return new FilenameFormat("tei", "xml");
		}
		return new FilenameFormat("unknown", "xml");
	}
	
}
