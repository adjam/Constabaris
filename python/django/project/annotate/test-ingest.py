#!/usr/bin/env python

from django.core.management import setup_environ
import settings
import sys

setup_environ(settings)

from works import ingest, admin

for filename in sys.argv[1:]:
	ctx = ingest.IngestContext(filename)
	action = ingest.IngestAction(ctx)
	print action.execute(commit=True)

