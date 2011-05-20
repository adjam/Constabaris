package edu.unc.lib.xproc;

/**
 * Exception thrown to indicate any kind of failure within a pipeline execution.
 * In general, this class wraps another exception.
 * @author adamc
 *
 */
public class PipelineFailureException extends Exception {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public PipelineFailureException() {
		super();
	}

	public PipelineFailureException(String message) {
		super(message);
	}

	public PipelineFailureException(Throwable cause) {
		super(cause);
	}

	public PipelineFailureException(String message, Throwable cause) {
		super(message, cause);
	}

}
