package edu.unc.lib.web.action;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.DigestOutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Collections;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileItemFactory;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import eu.medsea.util.MimeUtil;

/**
 * Request processor that extracts uploads for <code>multipart/form-data</code> as well as request entities.
 * Instances of this class are not designed for re-use.
 * @author adamc
 */
public class UploadHandler {
	
	private static final Logger logger = LoggerFactory.getLogger(UploadHandler.class);
	
	private MessageDigest checksum = null;
	
	private boolean multipart = false;
	
	private String fileName = null;
	
	private String mimeType = "application/octet-stream";

	private String encoding;

	private File workingDirectory;
	
	/**
	 * Creates a new upload handler whose working directory is the value of the
	 * system property <code>java.io.tmpdir</code>.
	 */
	public UploadHandler() {
		this( new File( System.getProperty("java.io.tmpdir") ) );
	}
	
	/**
	 * Creates a new upload handler with a specified working directory.
	 * @param workingDirectory the directory where the upload handler will
	 * store its files.
	 */
	public UploadHandler(File workingDirectory) {
		this.workingDirectory = workingDirectory;
	}
	
	public File doPost(HttpServletRequest req) throws IOException {
		multipart = ServletFileUpload.isMultipartContent(req);
		encoding = req.getCharacterEncoding();
		mimeType = req.getContentType();
		File destination = null;

		if ( !multipart ) {
			destination = getEntityAsFile(req);
		} else {
			destination = writeUploadToFile(req);
			multipart = true;
		}
		return destination;
	}
	
	protected File writeRequestEntityToFile(HttpServletRequest req) throws IOException {
		File temp = File.createTempFile(req.getMethod() + "-body-", ".tmp", workingDirectory);
		InputStream input = null;
		DigestOutputStream output = null;
		
		try {
			input = req.getInputStream();
			output = getDigestOutputStream(new FileOutputStream(temp));
			IOUtils.copy(input, output);
			checksum = output.getMessageDigest();
		} finally {
			IOUtils.closeQuietly(input);
			IOUtils.closeQuietly(output);
		}
		
		return temp;
	}
	
	public File getEntityAsFile(HttpServletRequest req) throws IOException {
		File destination = null;
		String method = req.getMethod();
		File temp = writeRequestEntityToFile(req);
		if ( mimeType == null ) {
			logger.debug("Unable to read MIME type from request, will use MIME 'magic' ...");
			mimeType = checkMimeType(temp);
		}
		if ( logger.isDebugEnabled() ) {
			logger.debug("Processing MIME type {} on {}", mimeType, temp.getAbsolutePath() );
		}
		if ( "application/zip".equals(mimeType) ) {
			destination = File.createTempFile("upload-" + method + "-", ".zip", workingDirectory);
		} else {
			destination = File.createTempFile("upload-" + method + "-", ".xml", workingDirectory);
		}
		destination.delete();
		FileUtils.moveFile(temp, destination);
		return destination;
	}
	
	@SuppressWarnings("unchecked")
	protected File writeUploadToFile(HttpServletRequest req) throws IOException {
		FileItemFactory factory = new DiskFileItemFactory();
		ServletFileUpload upload = new ServletFileUpload(factory);
		try {
			List<FileItem> items = Collections.checkedList(upload.parseRequest(req), FileItem.class);
			for( FileItem item: items ) {
				if ( !item.isFormField() ) {
					fileName = item.getName();
					mimeType = item.getContentType();
					String extension = FilenameUtils.getExtension(item.getName());
					File temp = File.createTempFile("ingest-upload-" , "." + extension, workingDirectory);
					InputStream input = null;
					DigestOutputStream output = null;
					try {
						input = item.getInputStream();
						output = getDigestOutputStream(new FileOutputStream(temp));
						IOUtils.copy(input, output);
						setChecksum(output.getMessageDigest());
						return temp;
					} finally {
						IOUtils.closeQuietly(input);
						IOUtils.closeQuietly(output);
					}
				}
			}
			
		} catch( FileUploadException fue ) {
			throw new IOException(fue);
		} catch( Exception x ) {
			logger.error("Some kinda craziness handling upload", x);
			throw new IOException(x);
		}
		throw new IllegalArgumentException("No file was uploaded");
	}
	
	private DigestOutputStream getDigestOutputStream(OutputStream stream) {
		try {
			return new DigestOutputStream( stream, MessageDigest.getInstance("SHA-1"));
		} catch (NoSuchAlgorithmException e) {
			throw new IllegalStateException("Unable to instantiate digest stream for SHA-1");
		}
	}
	
	private String checkMimeType(File file) {
		String type = MimeUtil.getMagicMimeType(file);
		if ( type == null ) {
			logger.debug("Unable to use MIME magic to determine type of " + file.getAbsolutePath());
			return "application/xml";
		}
		return type;
	}

	public boolean isMultipart() {
		return multipart;
	}
	
	/**
	 * Gets the name of the file as supplied by the client.
	 * @return
	 */
	public String getFileName() {
		return this.fileName;
	}

	private void setChecksum(MessageDigest checksum) {
		this.checksum = checksum;
	}

	/**
	 * Gets the checksum value of the uploaded file.
	 * @return
	 */
	public MessageDigest getChecksum() {
		return checksum;
	}

	/**
	 * Gets the MIME type of the uploaded file.  This value will either be derived from
	 * the Content-Type header or, if that is not provided, by guessing from the file extension.
	 * @return
	 */
	public String getMimeType() {
		return mimeType;
	}
	
	public String getEncoding() {
		return encoding;
	}

}
