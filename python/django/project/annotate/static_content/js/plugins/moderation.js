jQuery.fn.moderation = function(options) {
	var defaults = {}
	var opts = jQuery.extend(defaults.options);
	var comments = jQuery(".comment", this);
	jQuery(".unapproved", comments).fadeTo('fast',.5);
	var controls = jQuery(".moderator-controls", this);
	controls.live(
		'click', 
		function() {
			jQuery(".moderator-info", $(this).parent().parent()).toggle();
		}
	);
	
	var removalLinks = jQuery("a.removal-link", comments);
	removalLinks.parent().css({ float: 'right' }).click( function(evt) {
		evt.preventDefault();
		if ( confirm("Are you sure you want to remove this comment?") ) {
			var origComment = $(this).parents("div.comment");
			if ( !confirm(origComment.html()) ) {
				return;
			}
			jQuery.ajax({
					type: "DELETE",
					url: $(this).attr("href"),
					success : function(data, textStatus) { origComment.css({ display: 'none'}); },
					error :  function(data, textStatus) { alert("Unable to remove: " + textStatus); } }
			);
		}
	});
	return this;
};
