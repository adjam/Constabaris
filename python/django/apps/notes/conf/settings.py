from django.conf import settings


COMMENTS_HIDE_REMOVED = getattr(settings, "COMMENTS_HIDE_REMOVED", True)

# no. of seconds after comment is created to allow editing or deletions by user
COMMENTS_EDIT_GRACE_PERIOD = getattr(settings, "COMMENTS_EDIT_GRACE_PERIOD", 300)