from django.core.management.base import BaseCommand, CommandError
from optparse import make_option
import os

from apps.cdla_apps.works.models import Work

class Command(BaseCommand):
    option_list = BaseCommand.option_list + (
        make_option('--id', '-i', dest="id", help="ID of work to refresh"),
        make_option('--package', '-p', dest='package', help="Path to ingest package file"),
    )

    help = "Allows for re-ingest of broken or updated content"
    def handle(self,**options):
        print "Refresh Content"
        for k,v in options.items():
            print "Option:%s, value: %s" % ( k,v )
        if not 'id' in options or options['id'] is None:
            print "You must specify the ID of the work to be refreshed"
            return
        else:
            try:
                wk = Work.objects.get(pk=options['id'])
            except Work.DoesNotExist:
                print "No work found with id %s" % ( options['id'] )
                return
            print "Content directory for %s: %s" % ( wk, wk.get_content_directory() )
            for f in os.listdir(wk.get_content_directory()):
                
                print "\t", f

