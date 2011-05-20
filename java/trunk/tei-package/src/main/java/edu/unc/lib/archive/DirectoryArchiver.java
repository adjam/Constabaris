package edu.unc.lib.archive;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import org.apache.commons.io.DirectoryWalker;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Creates a zip file from a directory start point.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class DirectoryArchiver extends DirectoryWalker {

    private Logger logger = LoggerFactory.getLogger(DirectoryArchiver.class);

    private File archiveFile;

    /**
     * Creates an archiver with an auto-generated output file.
     */
    public DirectoryArchiver() {
        super(new UploadedArchiveFilter(), -1);
        try {
            archiveFile = File.createTempFile("ingest-", ".zip");
        } catch (IOException ioe) {
            throw new Error("Unable to create temporary directory", ioe);
        }
    }

    /**
     * Creates an archiver with a specified output file.
     * @param archiveFile the path where the output zip file will be stored.
     */
    public DirectoryArchiver(File archiveFile) {
        super(new UploadedArchiveFilter(), -1);
        this.archiveFile = archiveFile;
    }

    /**
     * Populates a zip file from a directory.
     * @param startDirectory the top level of the directory from which to create
     * the archive.
     * @return the path to the created ZIP.
     * @throws IOException if an error is encountered creating the zip.
     */
    public File getArchive(File startDirectory) throws IOException {
        String prefix = startDirectory.getAbsolutePath();
        List<File> packageFiles = getPackageFiles(startDirectory);
        //ZipFile zf = new ZipFile(archiveFile);
        ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(archiveFile));
        for (File f : packageFiles) {
            String archiveName = f.getAbsolutePath().substring(prefix.length() + 1);
            if ( logger.isDebugEnabled() ) {
                logger.debug("Adding " + f.getAbsolutePath() + " to " + archiveName);
            }

            ZipEntry entry = new ZipEntry(archiveName);
            zos.putNextEntry(entry);
            FileInputStream input = new FileInputStream(f);
            IOUtils.copy(input, zos);
            input.close();
            zos.closeEntry();
        }
        zos.close();
        return archiveFile;
    }

    /**
     * Gets the files that will be packaged into the output zip archive.
     * @param startDirectory the top level of the files that will be packaged into the
     * archive.
     * @return a list of the files that will be packaged.
     * @throws IOException if an error is encountered reading the filenames from dist.
     */
    public List<File> getPackageFiles(File startDirectory) throws IOException {
        List<File> packageFiles = new ArrayList<File>();
        walk(startDirectory, packageFiles);
        return packageFiles;
    }

    @SuppressWarnings("unchecked")
    @Override
    protected void handleFile(File file, int depth, Collection results)
            throws IOException {
        results.add(file);
    }
}
