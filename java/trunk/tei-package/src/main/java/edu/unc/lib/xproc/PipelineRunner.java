package edu.unc.lib.xproc;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;

import javax.xml.transform.stream.StreamSource;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.s9api.DocumentBuilder;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.trans.XPathException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xmlcalabash.core.XProcConfiguration;
import com.xmlcalabash.core.XProcException;
import com.xmlcalabash.core.XProcRuntime;
import com.xmlcalabash.model.RuntimeValue;
import com.xmlcalabash.runtime.XPipeline;

/**
 * Runs a Calabash XProc pipeline.  Unless otherwise configured (by using the requisite
 * constructor or the <code>setPipeline(url)</code> method), this will run
 * the pipeline document found at <code>/xpl/ingest.xpl</code> on the applications' classpath.
 * <p>
 *  Instances of this class fire property changes at various points to indicate to
 *  their callers that 'things are happening.'  However, these events aren't neatly
 *  mapped onto changes of <em>properties</em> of the instance, but rather notifications
 *  that certain events have occurred.  Java's property change infrastructure provided a
 *  faster path to implementing such an event system.
 *  @see Events for more information about the events that can be listened for.
 * </p>
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class PipelineRunner {

    private XProcConfiguration configuration;

    private final PropertyChangeSupport pcs = new PropertyChangeSupport(this);

    private URL pipelineURL;

    private PipelineResultHandler resultHandler;

    private XdmNode _pipelineNode;
    
    private static final Logger logger = LoggerFactory.getLogger(PipelineRunner.class);

    /**
     * Creates a new instance with a default configuration and the default URL for the
     * pipeline document.
     **/
    public PipelineRunner() {
        configuration = new XProcConfiguration(false);
        // note this may be null, depending on how the application is packaged.
        pipelineURL = getClass().getResource("/xpl/ingest.xpl");
    }

    /**
     * Sets the URL from which the pipeline document should be loaded.
     * @param pipelineURL a URL that points to a pipeline file.
     */
    public void setPipelineURL(URL pipelineURL) {
        this.pipelineURL = pipelineURL;
    }

    /**
     * Creates a new instance using the specified URL for the pipeline.
     * @param pipelineURL
     * @throws IllegalStateException
     */
    public PipelineRunner(URL pipelineURL) {
        this();
        this.pipelineURL = pipelineURL;
    }

    /**
     * Sets the handler that handles the output of the pipeline document.
     * @param resultHandler an object that handles the results of executing
     * the pipeline document.
     **/
    public void setResultHandler(PipelineResultHandler resultHandler) {
        this.resultHandler = resultHandler;
    }

    /**
     * Gets the object that handles the results of running the pipeline.
     **/
    public PipelineResultHandler getResultHandler() {
        return this.resultHandler;
    }

    /**
     * Executes the pipeline.
     * @param source a stream reading the XML document on the pipeline's <code>source</code> port.
     * @param outputDirectory the directory where the output of the pipeline's execution
     * should be stored.
     */
    public void runPipeline(InputStream source, File outputDirectory) throws PipelineFailureException {
        XProcRuntime runtime = null;
        try {
            runtime = new XProcRuntime(configuration);
            runtime.setPhoneHome(false);
            XPipeline pipeline = runtime.use(getPipelineNode()); //runtime.load(pipelineURL.toString());
            pipeline.clearInputs("source");
            pipeline.passOption(new QName("outputDirectory"), new RuntimeValue(outputDirectory.getAbsolutePath()));
            if (logger.isDebugEnabled()) {
                for (String input : pipeline.getInputs()) {
                    logger.debug("Input: {}", input);
                }
                for (String output : pipeline.getOutputs()) {
                    logger.debug("Output: {}", output);
                }
            }

            XdmNode inputNode = readStream(source);
            pipeline.writeTo("source", inputNode);
            if (resultHandler == null) {
                resultHandler = new DefaultPipelineResultHandler(runtime, pipeline);
                ((DefaultPipelineResultHandler) resultHandler).setOutputDirectory(outputDirectory);
            }
            pipeline.run();
            resultHandler.handleOutputs();
            firePropertyChange(Events.ACTION_COMPLETED, null, "Pipeline completed");
        } catch (XProcException xe) {
            if (xe.getStep() != null) {
                logger.error("XProc exception in step " + xe.getStep().getName() + " at location " + xe.getStep().getLocation());
            } else {
                logger.error("XProc exception (pipeline error?)", xe);
            }
            throw new PipelineFailureException(xe);
            //firePropertyChange(Events.ACTION_FAILED, null, xe);
        } catch (SaxonApiException e) {
            logger.error("Pipeline execution failed", e);
            throw new PipelineFailureException(e);
            //firePropertyChange(Events.ACTION_FAILED, null, e);
        } catch (RuntimeException rx) {
            if (rx.getCause() instanceof XPathException) {  // unchecked Saxon API exceptions ...
                XPathContext ctx = ((XPathException) rx.getCause()).getXPathContext();
                logger.error("XPath Context: " + ctx);
                if (ctx.getOrigin() != null) {
                    logger.error("Origin: " + ctx.getOrigin());
                }
            }
            throw rx;
        }
    }

    private synchronized Processor getProcessor() {
        return configuration.getProcessor();
    }

    private XdmNode getPipelineNode() throws SaxonApiException {
        if (_pipelineNode == null) {
            try {
                if (logger.isTraceEnabled()) {
                    logger.trace("Loading pipeline definition from {}", pipelineURL.toString());
                }
                _pipelineNode = readURL(pipelineURL);
                logger.trace("Pipeline loaded.");
            } catch (IOException ioe) {
                logger.error("IO exception loading pipeline", ioe);
                throw new RuntimeException(ioe);
            }
        }

        return _pipelineNode;
    }

    /**
     * Reads a document at a specified URL and returns its contents as
     * a Saxon API XdmNode.
     * @param url the location of the document.
     * @return the document at <code>url</code>, represented as an
     * <code>XdmNode</code>.
     * @throws SaxonApiException if the document cannot be properly parsed.
     * @throws IOException if the document cannot be read.
     **/
    XdmNode readURL(URL url) throws SaxonApiException, IOException {
        Processor p = getProcessor();
        DocumentBuilder builder = p.newDocumentBuilder();
        StreamSource source = new StreamSource(url.openStream(), url.toString());
        return builder.build(source);
    }

    /**
     * Reads a stream into an XdmNode.
     * @param input an input stream to an XML document.
     * @return the document as an XdmNode.
     * @throws SaxonApiException
     * @see readURL(url)
     */
    XdmNode readStream(InputStream input) throws SaxonApiException {
        Processor p = getProcessor();
        DocumentBuilder builder = p.newDocumentBuilder();
        StreamSource source = new StreamSource(input);
        return builder.build(source);
    }

    /**
     * Adds a listener for events fired by this object.
     * @param listener
     */
    public void addPropertyChangeListener(PropertyChangeListener listener) {
        pcs.addPropertyChangeListener(listener);
    }

    /**
     * Adds a listener for a particular property of this object that might change.
     * @param propertyName the property to which changes are being listened.
     * @param listener the object that wishes to receive change notifications.
     */
    public void addPropertyChangeListener(String propertyName,
            PropertyChangeListener listener) {
        pcs.addPropertyChangeListener(propertyName, listener);
    }

    public void fireIndexedPropertyChange(String propertyName, int index,
            boolean oldValue, boolean newValue) {
        pcs.fireIndexedPropertyChange(propertyName, index, oldValue, newValue);
    }

    public void fireIndexedPropertyChange(String propertyName, int index,
            int oldValue, int newValue) {
        pcs.fireIndexedPropertyChange(propertyName, index, oldValue, newValue);
    }

    public void fireIndexedPropertyChange(String propertyName, int index,
            Object oldValue, Object newValue) {
        pcs.fireIndexedPropertyChange(propertyName, index, oldValue, newValue);
    }

    public void firePropertyChange(PropertyChangeEvent evt) {
        pcs.firePropertyChange(evt);
    }

    public void firePropertyChange(String propertyName, boolean oldValue,
            boolean newValue) {
        pcs.firePropertyChange(propertyName, oldValue, newValue);
    }

    public void firePropertyChange(String propertyName, int oldValue,
            int newValue) {
        pcs.firePropertyChange(propertyName, oldValue, newValue);
    }

    public void firePropertyChange(String propertyName, Object oldValue,
            Object newValue) {
        pcs.firePropertyChange(propertyName, oldValue, newValue);
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
}
