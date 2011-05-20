package edu.unc.lib.data;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.xml.sax.SAXException;

/**
 * Class to handle simple validation against XHTML strict schema.  Instances of this class are thread-safe, at least
 * so long as the underlying implementation of Schema conforms to the documentation ...
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 *
 */
public class HTMLValidator {
	
	SchemaFactory schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
	
	Schema xhtmlSchema = null;
	
	public HTMLValidator() {
		InputStream is = getClass().getResourceAsStream("/xhtml1-strict.xsd");
		Source schemaSource = new StreamSource(is);
		try {
			xhtmlSchema = schemaFactory.newSchema(schemaSource);
		} catch( SAXException se ) {
			throw new ExceptionInInitializerError(se);
		}
	}
	
	
	public void validate(InputStream input) throws SAXException {
		Validator v = xhtmlSchema.newValidator();
		Source inputSource = new StreamSource(input);
		try {
			v.validate(inputSource);
		} catch (IOException e) {
			throw new SAXException(e);
		}
	}
	
	public static void main(String [] args) throws IOException {
		HTMLValidator validator = new HTMLValidator();
		for( String file : args ) {
			FileInputStream fis = new FileInputStream(file);
			try {
				validator.validate(fis);
				System.err.printf("Validated %s%n", file);
			} catch( SAXException se ) {
				System.err.printf("Invalid document %s -- %s%n", file, se.toString());
			}
				
		}
		
	}
	
	

}
