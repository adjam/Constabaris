package edu.unc.lib.data;

import java.io.IOException;
import java.net.URL;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpException;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.methods.HeadMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class that checks to see if something can be fetched from a specified URL.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class URLTester {
	
	
	private static final Logger logger = LoggerFactory.getLogger(URLTester.class);
	
	private HttpClient client;

        /**
         * Creates a new instance.
         */
	public URLTester() {
		this.client = new HttpClient();
	}

        /**
         * Tests to see whether a URL is retrievable by executing an HTTP HEAD
         * request against the URL.
         * @param url the URL to be checked.
         * @return <code>true</code> if the head request returns an HTTP "OK"
         * status, <code>false</code> otherwise.
         */
	public boolean testURLResolves(URL url) {
		HeadMethod method = new HeadMethod(url.toString());
		try {
			int status = client.executeMethod(method);
			
			if ( status != HttpStatus.SC_OK) {
				return false;
			}
			return true;
		} catch( HttpException hx ) {
			logger.warn("Unable to contact server at " + url.toString(), hx);
			return false;
		} catch( IOException iox ) {
			logger.warn("Unable to contact server at " + url.toString(), iox);
			return false;
		} finally {
			method.releaseConnection();
		}
	}

        /**
         * Disposes of background resources used by this object.
         */
	public void close() {
		if ( this.client != null ) {
			client.getHttpConnectionManager().closeIdleConnections(0);
		}
	}

}
