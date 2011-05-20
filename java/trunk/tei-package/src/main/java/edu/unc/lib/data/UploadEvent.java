package edu.unc.lib.data;

import java.io.File;
import java.io.Serializable;
import java.security.MessageDigest;
import java.util.Date;
import java.util.UUID;

import edu.unc.lib.ingest.IngestFileUtils;

/**
 * Represents the result of running a pipeline on an uploaded file.
 * Instances of this class are immutable.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class UploadEvent implements Serializable {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	private String originalName;
	
	private String mimeType;
	
	private long timestamp;
	
	private File uploadedFile;
	
	private File resultFile;
	
	private UUID id = UUID.randomUUID();

	private String encoding;

	private MessageDigest checksum;

	/**
	 * Creates a new, immutable upload event object.
	 * @param origName the original name of the uploaded file on the user's filesystem.
	 * @param uploadedFile the path to the uploaded file on the server.
	 * @param resultFile the path to the output of the pipeline processor.
	 * @param mimeType the MIME type of the uploaded file as reported by the user's browser.
	 * @param encoding the character encoding of the uploaded file.
	 * @param timestamp the time the upload occurred.
	 * @param checksum the 'hashed' value of the uploaded file.
	 */
	public UploadEvent(String origName, File uploadedFile, File resultFile, String mimeType, String encoding, long timestamp, MessageDigest checksum) {
		this.uploadedFile = uploadedFile;
		this.originalName = origName;
		this.mimeType = mimeType;
		this.encoding = encoding;
		this.timestamp = timestamp;
		this.checksum = checksum;
		this.resultFile = resultFile;
	}

	/**
	 * Gets this event's unique identifier.
	 * @return
	 */
	public UUID getId() {
		return id;
	}
	
	/**
	 * Gets the digest object for the uploaded file.
	 * @return
	 */
	public MessageDigest getChecksum() {
		return checksum;
	}
	
	/**
	 * Gets the message digest object as a string.
	 * @return a string of the form  of the form
	 * <code>{[digest algorithm name]}[hex digest]</code>, e.g.
	 * <code>{SHA-1}540985029fead</code>.
	 */
	public String getChecksumAsString() {
		StringBuilder sb = new StringBuilder("{");
		sb.append(checksum.getAlgorithm())
		.append("}");
		for( byte b : checksum.digest() ) {
			sb.append(Integer.toString( ( b & 0xff ) + 0x100, 16).substring( 1 ));
		}
		return sb.toString();
	}
	
	/**
	 * Gets the original name of the file that was uploaded.
	 * @return
	 */
	public String getOriginalName() {
		return originalName;
	}
	
	/**
	 * Gets the path to the location on the server where the uploaded file was stored.
	 * @return
	 */
	public File getUploadedFile() {
		return this.uploadedFile;
	}
	
	/**
	 * Gets the formatted size of the uploaded file.
	 * @return
	 */
	public String getUploadedFileSize() {
		return IngestFileUtils.formatFileSize(uploadedFile);
	}
	
	/**
	 * Gets the file that resulted from running the ingest processor.
	 * @return
	 */
	public File getResultFile() {
		return resultFile;
	}
	
	/**
	 * Gets a formatted string indicating the result file's size
	 * in megabytes.
	 * @return
	 */
	public String getResultFileSize() {
		return IngestFileUtils.formatFileSize(resultFile);
	}
	
	/**
	 * Gets the text encoding for the uploaded file.  <em>This value typically only
	 * matters if a bare <abbr>XML</abbr> file was uploaded</em>.
	 * @return
	 */
	public String getEncoding() {
		return this.encoding;
	}

	/**
	 * Gets the MIME type of the uploaded file.
	 * @return
	 */
	public String getMimeType() {
		return mimeType;
	}

	/**
	 * Gets the timestamp indicating when the upload took place.
	 * @return
	 */
	public long getTimestamp() {
		return timestamp;
	}

	/**
	 * Gets the timestamp indicating whent he fupload took place as
	 * a Date object.
	 * @return
	 */
	public Date getTimestampAsDate() {
		return new Date(timestamp);
	}
	
	/**
	 * @inheritDoc
	 */
	@Override
	public String toString() {
		return String.format("Upload: %s [%d bytes], %s, at %s; stored as %s", getOriginalName(), getUploadedFile().length(), getMimeType(), getTimestampAsDate().toString(), getUploadedFile().getName()); 
	}
}
