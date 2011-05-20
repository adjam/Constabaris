package edu.unc.lib.web.action;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.unc.lib.archive.DirectoryArchiver;
import edu.unc.lib.ingest.IngestFileUtils;
import edu.unc.lib.xproc.OutputRedirector;
import edu.unc.lib.xproc.PipelineFailureException;
import edu.unc.lib.xproc.PipelineRunner;

/**
 * Handles the creation of an ingest package, including running the pipeline
 * and packaging the results.
 * @author adamc
 */
public class IngestHandler {
	
	
	private PipelineRunner runner;
	
	private File inputFile;
	
	private File outputFile = null;

	private File outputDirectory;

	private Logger logger = LoggerFactory.getLogger(IngestHandler.class);
	
	private static final List<String> imageExtensions = Arrays.asList(new String [] { "jpg", "svg", "png", "gif" }); 

	public IngestHandler(PipelineRunner runner, File inputFile, File outputDirectory) {
		this.runner = runner;
		this.inputFile = inputFile;
		this.outputDirectory = outputDirectory;
	}
	
	public void execute() throws IOException, PipelineFailureException {
		if ( inputFile.getName().toLowerCase().endsWith(".zip" ) ) {
			processZip(inputFile);
		} else {
			processStandaloneFile(inputFile);
		}
		if ( outputFile == null ) {
			outputFile = File.createTempFile("ingest-", ".zip");
		}
		DirectoryArchiver archiver = new DirectoryArchiver(outputFile);
		outputFile = archiver.getArchive(outputDirectory);
		runner.getResultHandler().cleanup();
	}
	
	protected void processStandaloneFile(File inputFile) throws IOException, PipelineFailureException {
		InputStream input = new FileInputStream(inputFile);
		runner.runPipeline(input,outputDirectory);
	}


	protected void processZip(File inputFile) throws IOException, PipelineFailureException {
		ZipFile zip = new ZipFile(inputFile);
		ZipEntry entry = getXMLFromZip(zip);
		InputStream input = zip.getInputStream(entry);
		runner.runPipeline(input, outputDirectory);
		List<ZipEntry> images = findImages(zip);
		for( ZipEntry imgEntry : images ) {
			if ( logger.isTraceEnabled() ) {
				logger.trace("Found image in zip:" + imgEntry.getName() );
			}
			File outputPath = getOutputPath(imgEntry);
			ensureParentExists(outputPath);
			FileOutputStream fos = null;
			try {
				fos = new FileOutputStream(outputPath);
				IOUtils.copy(zip.getInputStream(imgEntry), fos);
			} finally {
				IOUtils.closeQuietly(fos);
			}
		}
	}
	
	private void ensureParentExists(File outputPath) throws IOException {
		IngestFileUtils.ensureParentExists(outputPath);
	}
	
	
	private File getOutputPath(ZipEntry entry) {
		return new File(outputDirectory, OutputRedirector.HTML_OUTPUT_PREFIX + entry.getName());
	}
	
	
	protected List<ZipEntry> findImages(ZipFile inputZip) {
		List<ZipEntry> images = new ArrayList<ZipEntry>();
		Enumeration<? extends ZipEntry> en = inputZip.entries();
		while( en.hasMoreElements() ) {
			ZipEntry entry = en.nextElement();
			if ( entry.getName().startsWith("__MACOSX") ) {
				continue;
			}
			if ( isImage(entry) ) {
				images.add(entry);
			}
		}
		return images;
	}
		
	private boolean isImage(ZipEntry entry) {
		String ext = FilenameUtils.getExtension(entry.getName());
		return imageExtensions.contains( ext.toLowerCase() );
	}
	
	/**
	 * Locates the input TEI in a ZIP archive.
	 * @param zip
	 * @return the entry named <code>tei.xml</code> in the archive, or the first entry found
	 * ending in <code>.xml</code> otherwise.
	 * @throws IllegalArgumentException if no entry can be found matching the above criteria.
	 */
	ZipEntry getXMLFromZip(ZipFile zip) {
		 ZipEntry entry = zip.getEntry("tei.xml");
		 if ( entry == null ) {
				for( Enumeration<? extends ZipEntry> en = zip.entries(); en.hasMoreElements(); ) {
					ZipEntry nextEntry = (ZipEntry)en.nextElement();
					if ( nextEntry.getName().toLowerCase().endsWith(".xml") ) {
						return nextEntry;
					}
					
				}
		 } else {
			 return entry;
		 }
		 throw new IllegalArgumentException("Unable to find input XML in supplied SIP");
	}
	
	public File getOutputFile() {
		return outputFile;
	}
	
	public void setOutputFile(File outputFile) {
		this.outputFile = outputFile;
	}

}
