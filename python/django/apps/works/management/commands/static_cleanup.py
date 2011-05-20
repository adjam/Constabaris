from django.core.management.base import BaseCommand, CommandError
from optparse import make_option
import os, shutil
from django.conf import settings



class Command(BaseCommand):
    #option_list = BaseCommand.option_list + (
    #    make_option('--id', '-i', dest="id", help="ID of work to refresh"),
    #    make_option('--package', '-p', dest='package', help="Path to ingest package file"),
    #)

    help = "Removes content under the web tree for works that have been deleted"
    
    
    def handle(self,**options):
        import apps.cdla_apps.works.models as models
        self.deletables = []
        ids = [ x.pk for x in models.Work.objects.all() ]
        if not len(ids):
            print "No works in database, exiting ..."
            return
        base_dir = os.path.abspath( os.path.join(settings.MEDIA_ROOT, "works") )
        work_dirs_available = [ int(x) for x in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, x)) and x.isdigit() ]
        work_dirs_available.sort()
        for wk_id in work_dirs_available:
            if not wk_id in ids:
                self.deletables.append(wk_id)
                target = os.path.join(base_dir, str(wk_id))
                tabs = os.path.abspath(target)
                assert tabs.startswith(base_dir)
                assert tabs != base_dir
                
                shutil.rmtree(tabs)
                
        
        
