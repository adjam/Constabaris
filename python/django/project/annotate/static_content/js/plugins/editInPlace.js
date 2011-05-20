(function() {
	var $ = jQuery;
	$.editable = {};
	$.editable.defaults = {
		onchange: 'change'
	};
	
	$.fn.editable = function(options) {
		var options = $.extend({},$.editable.defaults, options);
		return this.each( function() {
			var edit = $(this);
			var prev = edit.html();
			
			function startEditing() {
				edit.attr('contentEditable', true);
				edit.addClass('editing');
			}
			
			function stopEditing() {
				edit.attr('contentEditable', false);
				edit.removeClass('editing');
			}
			
			edit.keyup( function(evt) {
				if (edit.keyCode == 13 && edit.attr('contentEditable') == 'true' ) {
					stopEditing();
					alert("Done: (" + edit.html() + ")");
				}
				return true;
			});
			
			
			edit.click( function(evt) {
				if ( edit.attr('contentEditable') == 'true' ) {
					stopEditing();
				} else {
					startEditing();
				}
			});
		});
	}
	
	
})();
	
