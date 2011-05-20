from django.conf import settings

import os, tempfile

WORKS_BROWSE_PAGESIZE = getattr(settings, 'WORKS_BROWSE_PAGESIZE', 20)

HAYSTACK_SOLR_URL = getattr(settings,'HAYSTACK_SOLR_URL', 'http://localhost:8080/solr/voice')

PACKAGER_SERVICE_URL = getattr(settings,"PACKAGER_SERVICE_URL","http://localhost:8080/tei-package/service/")

MISSING_IMAGE_URL = getattr(settings, "MISSING_IMAGE_URL", "/voice/static/images/image-missing.jpg")

ATTIC = getattr(settings, "ATTIC", os.path.join(tempfile.gettempdir(), "works", "attic"))

