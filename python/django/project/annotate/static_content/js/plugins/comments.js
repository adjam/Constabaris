var tinyMCEInitialized = false;

/**
 * Sets the tab index on the tiny MCE toolbar controls to -1 so
 * that users can more easily tab into the editor window.
 **/
function setTabIndex() {
	var count = jQuery(".mceToolbar a").attr("tabIndex", -1).size();
}

function insertLink() {
		alert("CLICKITY");
}


function initTinyMCE() {
  if ( !tinyMCEInitialized ) {
    tinyMCE.init( {
      	'plugins' : "paste,searchreplace,inlinepopups",
		"mode" : "exact",
		"theme" : "advanced",
		// "skin" : "o2k7",
		"content_css": "/medea/css/styles.css",
		"theme_advanced_buttons1" : "bold,italic,separator,bullist,numlist,separator,link,unlink,separator,replace,separator,pasteword,cleanup,separator",
		"paste_auto_cleanup_on_paste" : "true",
		"theme_advanced_buttons2" : "",
		"theme_advanced_buttons3" : "",
		"theme_advanced_resizing" : true,
		"insertlink_callback" : "insertLink",
		
	//"theme_advanced_disable" : "underline,strikethrough,justifyleft,justifyright,justifycenter,justifyfull,outdent,indent,image,code,hr,fontselect,fontsizeselect,formatselect,styleselect,cleanup,sub,sup,forecolor,backcolor,visualaid,anchor,newdocument,undo,redo",
	"theme_advanced_toolbar_location" : "top",
	"init_instance_callback" : "setTabIndex",
	}
    );
    tinyMCEInitialized = true;
  }
}



jQuery.fn.commentify = function(options) {
  var defaults = {
    hide_comments: true,
    comments: jQuery("#comments"),
    hook_class: "annotation-hook",
    form: jQuery("form.comment-form"),
    internal_path_id: "id_content_internal_path"
  };
  
  var opts = jQuery.extend(defaults,options);

  /**
   * Form input element that holds the value of the currently selected
   * paragraph
   **/
  var $targetParagraph = jQuery("#" + opts['internal_path_id']);
  
  /**
   * jQuery object pointing at the comment container element.
   **/
  var $comments = opts['comments'];
  
  /**
   *  Container (within comment element) to which current comments will be copied
   **/
  var $currComment = $("#current-comments");
  
  var $defaultContents = $currComment.html();
  
  /**
   * The ID of the paragraph that was last selected.
   **/
  var $lastSelected = '';
  
  var $selectCurrentTab = function(event,ui) { // ui => the tab that was selected
	var $idx = ui.index;
	if ( $idx == 1 ) {
		var $pid = $targetParagraph.val();
		if ( window.console ) {
			window.console.log("Selected paragraph " + $pid );
		}
		if ( $pid && !($lastSelected == $pid) ) {
			$currComment.empty();
			var count = $("div.comment." + $pid, $comments).clone().prependTo($currComment).size();
			jQuery("#cp-size").html(count);
			if ( count == 0 ) {
				$currComment.html( $defaultContents );
			}
			$lastSelected = $pid;
		}
	}
  };
	
  var $tabs = $("#tabcontainer").tabs({	select: $selectCurrentTab });
  if ( opts['hide_comments'] ) {
    $comments.hide();
  }
  
  
  
  jQuery("p[id] ." + opts.hook_class).live('click',
    function() {
      var pid = $(this).parent().attr('id');
      showForm($(this).parent());
    }
  );
  /**
   * Since p tags inside blockquotes look funny, and are usually quotes from somewhere
   * else anyhow, don't provide markers for them.
   **/
  jQuery("p[id]", this).each( function() {
	  var excluded = $(this).parents("div.figure, blockquote");
	  if ( excluded.size() == 0 ) {
		var pid = $(this).attr('id');
		var targetedComments = jQuery("div#comments ." + pid);
		$(this).prepend("<div class='" + opts['hook_class'] + ( targetedComments.size() == 0 ? ' hidden' : '') + "'><span class='count'>" + targetedComments.size() + "</span></div>");
		/*
		.each(
			function() {
				var span = jQuery("span.count", this);
				window.console.log(span.text());
				if ( parseInt(span.text()) == 0 ) {
					span.addClass("hidden");
				}
			});		
		*/
	  }
  });
  
  jQuery("." + opts.hook_class).hoverIntent( function() { $(this).css({ cursor: 'pointer'}) },
	    function() { $(this).css( { cursor : 'default'}) });
    
  var $formResult;
  
  function handleForm(data,textStatus) {
	  if ( !$formResult ) {
		jQuery("body").append("<iframe id='form-result'/>");
		$formResult = jQuery("#form-result");
	  }
	  $formResult.html(data);
  }
  
  opts['form'].submit(
    function() {
      try {
	var postVars = $(this).serialize();
	jQuery.post(opts['form'].attr('action'), postVars, handleForm);
      } catch(e) {
	return confirm(e);
      }
      return false;
    }
   );
  
  $comments.dialog(
      {
	open: function() {
	  jQuery("textarea", opts.form).each( function() {
	    initTinyMCE();
	    tinyMCE.execCommand('mceAddControl', false, $(this).attr('id'));
	  });
	},
	width: 600,
	autoOpen: false,
	title: 'Comments'
      }
    );
  function showForm(source) {
    $targetParagraph.val( source.attr('id') );
	jQuery("p[id]", source.parent()).removeClass("active");
    source.addClass("active");
	if ( !$comments.dialog('isOpen') ) {
		$comments.dialog('open');
	}
	jQuery("#show-current-comments").click();
	$selectCurrentTab({}, { 'index' : 1 });
	// need to remove the tinyMCE 'control' on close, because otherwise
	// the dialog is only good for one 'open' on a pageview.
    $comments.dialog('option', 'beforeclose', function() {
	  source.removeClass('active');
	  jQuery("textarea", opts.form).each( function() {
	    tinyMCE.execCommand('mceRemoveControl', false,$(this).attr('id'));
	  });
    });
   }
   
  return this;
}

jQuery.fn.footnotes = function(options) {
  var defaults = {
    position: 'bottom',
    hide_delay: 1000
  };
  jQuery("div.body").append("<div id='noteDisplay'/>");
  
  var bodyWidth = jQuery("div.body").width();
  
  var noteDisplay = jQuery("#noteDisplay");
  
  noteDisplay.css({width: bodyWidth + 'px'});
  
  var opts = jQuery.extend(defaults,options);
  
  this.each(
    function() {
      var noteref = $(this);
      var showNote = function() {
        var note = jQuery(".inline-note", noteref);
        noteDisplay.html(note.html());
        if ( !noteDisplay.is(":visible") ) {
          noteDisplay.slideDown('fast');
        }
      };
  
      var hideNote = function() {
        //noteDisplay.animate({opacity:'100%'}, opts.hide_delay);
        noteDisplay.slideUp('fast');
      };
      noteref.hoverIntent( showNote, hideNote );
    }
  );
  
  return this;
}



jQuery.fn.paragraphLinks = function(opts) {
	jQuery("span.pagenum").each( 
		function() {
			var $p = jQuery(this);
			var $num = $p.text();
			var $id = $p.attr('id');
			$p.html("<a href='#" + $id + "><span>" + $num + "</span></a>");
			$p.hoverIntent( function() {
				jQuery("span.pb-display",jQuery(this).parent()).show();
			},
			function() {
				jQuery("span.pb-display",jQuery(this).parent()).hide();
			}
		).before("<span class='pb-display'>[" + ($num > 1 ? parseInt($num-1) : "") + "/" + $num + "]</span>")
		});
		
			
			
	jQuery("p[id]", this).each( function() {
		$(this).append('<a class="plink" href="#' + $(this).attr('id') + '">¶</a>');
	}).hoverIntent( 
		function() {
				$("a.plink", this).show();
		},
		function() {
				$("a.plink", this).hide();
		});
		
	return this;
}

jQuery.fn.searchHover = function(opts) {
	var $orig = $(this).attr("src");
	var $active = opts.active;
	$(this).hover( 
		function() {
			$(this).attr( {src : $active});
		},
		function() {
			$(this).attr({ src : $orig });
		}
	);
	
	return this;
}	
	
	

jQuery.fn.citation = function() {
  var cite = this;
  this.hide();
  var citeLink = jQuery("<a href='#'>Cite This Work</a><span>&#160;&#160;</span>");
  citeLink.insertBefore(cite);
  citeLink.click( function() {
    cite.toggle();
  });
}
