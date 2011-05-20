package edu.unc.lib.xproc;

public interface PipelineResultHandler {
	
	
	/**
	 * Processes the outputs from an XProc pipeline.
	 */
	public void handleOutputs();
	
	
	public void cleanup();

}
