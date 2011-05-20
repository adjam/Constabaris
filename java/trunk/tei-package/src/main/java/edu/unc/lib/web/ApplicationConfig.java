package edu.unc.lib.web;

import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.io.File;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import edu.unc.lib.web.listeners.UploadContextListener;

/**
 * Holds application-scoped attributes while allowing synchronized modification.
 * @author adamc, $LastChangedBy$
 *
 */
public class ApplicationConfig {
	
	public static final String ATTRIBUTE_NAME = ApplicationConfig.class.getName();
	
	private PropertyChangeSupport pcs = new PropertyChangeSupport(this);
	
	public void addPropertyChangeListener(PropertyChangeListener listener) {
		pcs.addPropertyChangeListener(listener);
	}

	public void addPropertyChangeListener(String propertyName,
			PropertyChangeListener listener) {
		pcs.addPropertyChangeListener(propertyName, listener);
	}

	public PropertyChangeListener[] getPropertyChangeListeners() {
		return pcs.getPropertyChangeListeners();
	}

	public PropertyChangeListener[] getPropertyChangeListeners(
			String propertyName) {
		return pcs.getPropertyChangeListeners(propertyName);
	}

	public boolean hasListeners(String propertyName) {
		return pcs.hasListeners(propertyName);
	}

	public void removePropertyChangeListener(PropertyChangeListener listener) {
		pcs.removePropertyChangeListener(listener);
	}

	public void removePropertyChangeListener(String propertyName,
			PropertyChangeListener listener) {
		pcs.removePropertyChangeListener(propertyName, listener);
	}

	private Map<String,String> vars = new ConcurrentHashMap<String,String>();
	
	/**
	 * Gets an unmodifiable view of the configuration variables.
	 * @return
	 */
	public Map<String,String> getConfiguration() {
		return Collections.unmodifiableMap(vars);
	}
	
	/**
	 * Sets a string-valued variable.
	 * @param key the name of the variable.
	 * @param value the value of the variable.
	 */
	public void setVariable(String key, String value) {
		String oldValue = vars.get(key);
		vars.put(key,value);
		pcs.firePropertyChange(key,oldValue, value);
	}
	
	public String getVariable(String key) {
		return vars.get(key);
	}
	
	public File getUploadDirectory() {
		String sVal = vars.get(UploadContextListener.BASE_UPLOAD_DIRECTORY);
		if ( sVal != null ) {
			return new File(sVal);
		}
		return new File( System.getProperty("java.io.tmpdir") );
	}
	
	public String getAssetLocationString() {
		return vars.get(UploadContextListener.XPROC_LOCATIONS);
	}
	
	public List<String> getAssetLocations() {
		String sVal = vars.get(UploadContextListener.XPROC_LOCATIONS);
		if ( sVal != null ) {
			return Arrays.asList(sVal.split(","));
		}
		return Collections.emptyList();
	}
	
	public void setAssetLocations(String ... locations) {
		StringBuffer sb = new StringBuffer();
		for (String loc : locations ) {
			sb.append(loc);
			sb.append(",");
		}
		sb.deleteCharAt(sb.length() -1);
		setVariable(UploadContextListener.XPROC_LOCATIONS, sb.toString());
	}
		

}
