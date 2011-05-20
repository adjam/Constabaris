package edu.unc.lib.ingest;

import java.io.File;

public class DefaultIngestContext implements IngestContext {
	
	private File inputFile;
	
	private File outputFile;
	
	//private ZipFile outputZip;

	public File getInputFile() {
		return inputFile;
	}
	
	public void setInputFile(File inputFile) {
		this.inputFile = inputFile;
	}

	public void setOutputFile(File outputFile) {
		this.outputFile = outputFile;
	}
	
	public File getOutputFile() {
		return outputFile;
	}

}
