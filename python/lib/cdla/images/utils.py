from PIL import Image
from base64 import b64encode
from cStringIO import StringIO

def read_image(data):
    """Gets a PIL.Image object from either byte data or a file-like object
    Arguments:
    
    data -- a byte string or file-like object.
    """
    if not hasattr(data,'read'):
        data = StringIO(data)
    return Image.open(data)

def get_thumbnail(img,size=None,max_dimension=64):
    """
    Gets a thumbnail copy of the supplied image.
    Arguments:
    
    img -- a PIL.Image object
    
    Keyword Arguments:
    
    size -- an (x,y) tuple indicating the width and the height
    max_dimension -- the size of the longest dimension
    in the resized image (preserves original aspect ratio).
    
    If `size` is specified it will override `max_dimension`.
    """
    cp = img.copy()
    if size is None:
        size = (max_dimension,max_dimension)
        #x,y = img.size
        #scale_factor = float( max(x,y) ) / float(max_dimension)
        #size = ( int(float(x)/scale_factor), int(float(y)/scale_factor) )
    cp.thumbnail(size,Image.ANTIALIAS) # best quality
    return cp

def get_data_url(img,format="image/png"):
    """
    Gets the data: URI for the supplied image.
    
    Arguments:
    
    img -- a PIL.Image object
    
    Keyword Arguments:
    
    format -- the MIME type of the output format; this is only
    required if the supplied image does not have its format set; PNG will
    be assumed otherwise
    @see PIL.Image.format
    """
    if img.format is not None:
        fmt_value = img.format
        format = "image/" + img.format.lower()
    else:
        fmt_value = "PNG"
    output = StringIO()
    img.save(output,fmt_value)
    rv = "data:%s;base64,%s" % (format, b64encode(output.getvalue()))
    output.close()
    return rv

if __name__ == '__main__':
    import sys
    for fn in sys.argv[1:]:
        img = Image.open(fn)
        thumb = get_thumbnail(img,(32,32))
        print get_data_url(thumb)



