/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package edu.unc.lib.archive;

import java.io.File;
import java.io.FileFilter;

/**
 * FileFilter implementation that excludes files in ingest packages that don't
 * belong.  Currently this amounts to rejecting files named <code>__MACOSX</code>.
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class UploadedArchiveFilter implements FileFilter {
    
    @Override
    public boolean accept(File pathname) {
        if ( "__MACOSX".equals(pathname.getName()) ) {
            return false;
        }
        return true;
    }
}
