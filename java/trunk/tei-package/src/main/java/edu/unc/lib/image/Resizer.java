package edu.unc.lib.image;

import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.Transparency;
import java.awt.image.BufferedImage;
import java.io.File;

import javax.imageio.ImageIO;

/**
 * Image resizer. This is just an idea that is not actually fit into the flow of uploads. 
 * @author adamc, $LastChangedBy$
 * @version $LastChangedRevision$
 */
public class Resizer {
	
	public BufferedImage getScaledInstance(BufferedImage img, int targetWidth,
			int targetHeight, Object hint, boolean higherQuality) {
		int type = (img.getTransparency() == Transparency.OPAQUE) ? BufferedImage.TYPE_INT_RGB
				: BufferedImage.TYPE_INT_ARGB;
		BufferedImage ret = (BufferedImage) img;
		int w, h;
		if (higherQuality) {
			// Use multi-step technique: start with original size, then
			// scale down in multiple passes with drawImage()
			// until the target size is reached
			w = img.getWidth();
			h = img.getHeight();
		} else {
			// Use one-step technique: scale directly from original
			// size to target size with a single drawImage() call
			w = targetWidth;
			h = targetHeight;
		}

		do {
			if (higherQuality && w > targetWidth) {
				w /= 2;
				if (w < targetWidth) {
					w = targetWidth;
				}
			}

			if (higherQuality && h > targetHeight) {
				h /= 2;
				if (h < targetHeight) {
					h = targetHeight;
				}
			}

			BufferedImage tmp = new BufferedImage(w, h, type);
			Graphics2D g2 = tmp.createGraphics();
			g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, hint);
			g2.drawImage(ret, 0, 0, w, h, null);
			g2.dispose();

			ret = tmp;
		} while (w != targetWidth || h != targetHeight);

		return ret;
	}
	
	public static void main( String[] args ) throws Exception {
		Resizer r = new Resizer();
		for (String arg : args) {
			File f = new File(arg);
			BufferedImage img = ImageIO.read(f);
			int w, h, tw, th;
			w = img.getWidth();
			h = img.getHeight();
			if ( w > h ) {
				tw = 128;
				th = (int)( 128f *( (float)h / (float)w ) );
			} else if (h > w ) {
				th = 128;
				tw = (int)( 128f * (float)w / (float)h);
			} else {
				tw = th = 128;
			}
			
			BufferedImage scaled = r.getScaledInstance(img,tw,th,RenderingHints.VALUE_INTERPOLATION_BILINEAR, true);
			File output = new File(f.getParent(), "thumbnail-" + f.getName());
			ImageIO.write( scaled, "PNG", output);
			System.out.println("Wrote image to " + output.getCanonicalPath());
		}
	}
}
