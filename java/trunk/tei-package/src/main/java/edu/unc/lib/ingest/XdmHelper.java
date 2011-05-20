package edu.unc.lib.ingest;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import net.sf.saxon.s9api.Axis;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XdmItem;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XdmNodeKind;
import net.sf.saxon.s9api.XdmSequenceIterator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Utility class that provides functions for dealing with Saxon 9 XDM objects.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 *
 */
public class XdmHelper {
	
	private static final Logger logger = LoggerFactory.getLogger(XdmHelper.class);
	
	public static void serializeToFile(XdmNode node, Processor processor, File outputFile) throws SaxonApiException, IOException {
		Serializer s = new Serializer();
		s.setOutputProperty(Serializer.Property.METHOD, "xml");
		s.setOutputProperty(Serializer.Property.ENCODING, "utf-8");
		s.setOutputProperty(Serializer.Property.OMIT_XML_DECLARATION, "yes");
		s.setOutputProperty(Serializer.Property.INDENT, "yes");
		FileOutputStream fos = new FileOutputStream(outputFile);
		s.setOutputStream(fos);
		processor.writeXdmValue(node, s);
		fos.flush();
		fos.close();
		if ( logger.isTraceEnabled() ) {
			logger.trace("Done writing {}", outputFile.getAbsolutePath());
		}
	}
	
	/**
	 * Serializes a node to a temporary file.
	 * @param node the node to be serialized.
	 * @param processor the processor used to create the node; if it is derived from some other source,
	 * you are likely to get an "Unknown Name Code" error from deep within the Saxon9 API.
	 * @return the file to which the node was serialized.
	 * @throws SaxonApiException
	 * @throws IOException
	 */
	public static File serializeToTempFile(XdmNode node, Processor processor) throws SaxonApiException, IOException {
		if ( node == null ) {
			throw new IllegalArgumentException("'node' argument cannot be null");
		}
		if ( processor == null ) {
			throw new IllegalArgumentException("'processor' argument cannot be null");
		}
		File outputFile = File.createTempFile("saxon-", ".xml");
		serializeToFile(node, processor, outputFile);
		return outputFile;
	}
	
	/**
	 * Gets the namespace URI for the root element of a document node. This is intended
	 * to identify the 'type' of document (e.g. TEI, METS, MODS) in cases where the node
	 * does not have a base URI.
	 * @param node a document node.
	 * @return the URI of the namespace of the root node, or the empty string if it has
	 * no namespace or <code>node</code> is not a document node.
	 */
	public static final String getRootNodeNamespace(XdmNode node) {
		XdmNodeKind nodeKind = node.getNodeKind();
		if ( XdmNodeKind.DOCUMENT.equals( nodeKind ) ) {
			// find root element and its namespace
			XdmSequenceIterator seqIter = node.axisIterator(Axis.CHILD);
			while( seqIter.hasNext() ) {
				XdmItem item = seqIter.next();
				if ( item instanceof XdmNode && ((XdmNode)item).getNodeKind() == XdmNodeKind.ELEMENT ) {
					return ((XdmNode)item).getUnderlyingNode().getURI();
				}
			}
		} else {
			logger.error("Unable to determine namespace for node of type {}", nodeKind.name() );
		}
		return "";
	}

}
