package edu.unc.lib.data;

import java.io.File;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public class UploadSession implements Serializable {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	private List<UploadEvent> events = new ArrayList<UploadEvent>();
	
	private File outputDirectory;
	
	public UploadSession(File outputDirectory) {
		this.outputDirectory = outputDirectory;
	}
	
	public File getOutputDirectory() {
		return this.outputDirectory;
	}
	
	public List<UploadEvent> getEvents() {
		return Collections.unmodifiableList(events);
	}
	
	public void addEvent(UploadEvent event) {
		events.add(event);
	}
	
	public boolean removeEvent(UploadEvent event) {
		return events.remove(event);
	}
	
	public UploadEvent getById(String uuid) {
		UUID toMatch = UUID.fromString(uuid);
		for ( UploadEvent evt : events ) {
			if ( toMatch.equals(evt.getId()) ) {
				return evt;
			}
		}
		return null;
	}
	
	public String getSessionAsString() {
		StringBuilder builder = new StringBuilder();
		for( UploadEvent event : events ) {
			builder.append("[")
			.append(event.getTimestampAsDate())
			.append("]")
			.append(" ")
			.append(event.getOriginalName())
			.append("<")
			.append(String.valueOf(event.getUploadedFile().length()))
			.append(">")
			.append(" => ")
			.append(event.getUploadedFile().getName())
			.append(" : ")
			.append(event.getMimeType())
			.append("\n");
		}
		return builder.toString();
	}

}
