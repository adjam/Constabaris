package edu.unc.lib.ingest;

import java.io.File;

import edu.unc.lib.web.action.IngestHandler;
import edu.unc.lib.xproc.PipelineRunner;

public class Main {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		try {
			String filename = args.length > 0 ? args[0] : "/home/adamc/Documents/lcrm/our-separate-ways.xml";
			Main main = new Main();
			File outputDir = IngestFileUtils.createTempDir(true);
			PipelineRunner runner = new PipelineRunner(main.getClass().getResource("/xpl/ingest.xpl"));
			IngestHandler handler = new IngestHandler(runner, new File(filename), outputDir );
			handler.setOutputFile(new File( outputDir, "ingest.zip") );
			handler.execute();
			System.out.printf("Output is in %s%n", handler.getOutputFile().getAbsolutePath());
		} catch( Exception e ) {
			e.printStackTrace(System.err);
		}
		
		

	}

}
