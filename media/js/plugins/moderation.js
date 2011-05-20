/**
 * Javascript to add in-place moderation.
 **/

jQuery.fn.moderation = function(options) {
	var defaults = {};
	var container = jQuery(this);
	var opts = jQuery.extend(defaults.options);
	var comments = jQuery(".comment", container);
	jQuery(".unapproved", comments).fadeTo('fast',.5);
	var controls = jQuery(".moderator-controls", this);
	controls.live(
		'click', 
		function() {
			jQuery(".moderator-info", $(this).parent().parent()).toggle();
		}
	);
	
	function removeFromDOM(target, cid) {
		var removed = jQuery("." + cid, container).remove();
		logit("Removed " + removed.size() + " comments from DOM");
		// note that this is an href value, so usable directly as selector
		var commentTargetId = jQuery('.ctop', target).attr('href');
		updateCommentCounts(commentTargetId);
	}
	
	var removalLinks = jQuery("a[rel=delete]", comments);
	var clicks = removalLinks.live('click', 
        function(evt) {
		    evt.preventDefault();
		    if ( confirm("Are you sure you want to remove this comment?") ) {
			    var origComment = $(this).closest("div.comment");
			    var classes = origComment.attr('class').split(' ');
			    var cid = '';
			    for(var i = 0; i< classes.length; i++) {
			    	var cls = classes[i];
			    	if ( cls.substring(0,4) == 'cid-' ) {
			    		cid = cls;
			    		break;
			    	}
			    }
    			jQuery.ajax({
	    				type: "POST",
                  data: { 'action' : 'DELETE' },
			    		url: $(this).attr("href"),
				    	success : function(data, textStatus) { removeFromDOM(origComment, cid); },
					   error :  function(data, textStatus) { alert("Unable to remove: " + textStatus); } }
    			);
		}
        return false;
	}).size();
	return this;
};
