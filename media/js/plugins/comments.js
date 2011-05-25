var tinyMCEInitialized = false;

/**
 * Sets the tab index on the tiny MCE toolbar controls to -1 so
 * that users can more easily tab into the editor window.
 **/
function setTabIndex() {
    var count = jQuery(".mceToolbar a").attr("tabIndex", -1).size();
}

function initTinyMCE() {
    if (!tinyMCEInitialized) {
        tinyMCE.init({
            'plugins': "paste,searchreplace,inlinepopups",
            "mode": "exact",
            "theme": "advanced",
            // "skin" : "o2k7",
            //	"content_css": "/voice/static/css/styles.css",
            "theme_advanced_buttons1": "bold,italic,separator,bullist,numlist,separator,link,unlink,separator,replace,separator,pasteword,cleanup,separator",
            "paste_auto_cleanup_on_paste": "true",
            "theme_advanced_buttons2": "",
            "theme_advanced_buttons3": "",
            "theme_advanced_resizing": true,
            "insertlink_callback": "insertLink",

            //"theme_advanced_disable" : "underline,strikethrough,justifyleft,justifyright,justifycenter,justifyfull,outdent,indent,image,code,hr,fontselect,fontsizeselect,formatselect,styleselect,cleanup,sub,sup,forecolor,backcolor,visualaid,anchor,newdocument,undo,redo",
            "theme_advanced_toolbar_location": "top",
            "init_instance_callback": "setTabIndex",
            "width": "100%",
            "height": "300px"
        }
        );
        tinyMCEInitialized = true;
    }
};

/**
 * this was an idea to add in-page navigation between sections on the page; primary idea is to select all of the h(n+1) elements under the top-level h(n) element
 * found in the content div, add IDs to them if needed, and then add the links.  Note this requires that the page template contain certain elements.
 **/
jQuery.fn.subnavigation = function(node, options) {
    var el = jQuery(node);
    var subList = jQuery("#si-subsections");
    subList.addClass("localNavigation");
    var headers = jQuery("h3", el);
    headers.each(function() {
        subList.append("<li>" + jQuery(this).text() + "</li>");
    });
};

function loadEditor(html) {
    tinyMCE.activeEditor.setContent(html);
}

/**
 * Copies the selected element ("previous/next" navigation elment)
 * and fixes the copy at the bottom of the screen.
 * options: not currently used.
 **/
jQuery.fn.navigationBar = function(options) {
    var $navbar = this.clone();
    jQuery("#body").append($navbar);
    $navbar.css({
        position: "fixed",
        bottom: 0,
        width: "100%",
        borderTop: "3px solid #000",
        fontFamily: "'Lucida Grande', 'Lucida Sans Unicode', sans-serif",
        backgroundColor: "#fafafa",
        zIndex: '100'
    });
};

/**
 * Updates all comment counters on page, including
 * global counters, current paragraph counters (on tab), and
 * if a targetId is specified, on the target.
 **/
function updateCommentCounts(targetId) {
    var $allCount = jQuery("#all-comments .comment").size();
    var $parCount = jQuery("#current-comments .comment").size();
    jQuery(".commentCount .count").text($allCount);
    jQuery("#show-current-comments .count").text($parCount);
    if (targetId) {
        var $markerCount = jQuery("#all-comments .ctop[href='" + targetId + "']").size();
        jQuery(targetId + " .count").text($markerCount);
    }
    if($allCount > 0){
        if(!$(".work-sections .section.current a").hasClass('has-comments')){
            $(".work-sections .section.current a").addClass('has-comments');
        }
    }else{
        $(".work-sections .section.current a").removeClass('has-comments');
    }
}

/**
 * Master commenting function; this is responsible for calling all the other plugins that enable the 
 * commenting feature.
 * options:
 * hide_comments (default true): whether the element that contains the comments should be hidden.
 * comments: jQuery object matching the  element that contains the comments.
 * hook_class: name of the class to use for elements that are used to display "comment on this paragraph" links.
 * form: jQuery object representing the form used to enter comments.
 *  internal_path_id: ID of the form element used to indicate the ID of the element being commented on.
 **/
jQuery.fn.commentifyold = function(options) {
    var defaults = {
        hide_comments: true,
        comments: jQuery("#comments-dialog"),
        hook_class: "annotation-hook",
        form: jQuery("form.comment-form"),
        internal_path_id: "id_content_internal_path"
    };

    var opts = jQuery.extend(defaults, options);

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
    $currComment.data('defaultContent', $currComment.html());
    $currComment.resetText = function() {
        $currComment.html($currComment.data('defaultContent'));
    };

    // save the value that's there (which is what the HTML page author specified
    //
    var $defaultContents = $currComment.html();

    var $theForm = opts['form'];

    if (commentables.size() == 0) {
        // nothing commentable on the page, so
        // hide everything
        $comments.hide();
        jQuery("#globalCommentCount").parent().hide();
        return this;
    }

    function getCommentsForTarget(target) {
        return jQuery(".comment." + target.attr("id"), $comments);
    }


    // write the count into the global counter spot; this is progressive enhancement
    updateCommentCounts();

    /**
   * The ID of the paragraph that was last selected.
   **/
    var $lastSelected = '';

    var $selectCurrentTab = function(event, ui) {
        // ui => the tab that was selected
        var $idx = ui.index;

        if ($idx == 0) {
            // first tab, 'all comments'
        } else if ($idx == 1) {
            // second tab,current Paragraph
            var $pid = $targetParagraph.val();
            if ($pid && !($lastSelected == $pid)) {
                var target = jQuery("#" + $pid);
                var localComments = getCommentsForTarget(target);
                if (localComments.size() == 0) {
                    jQuery("div.comment", $currComment).remove();
                    $currComment.resetText();
                } else {
                    var clones = localComments.clone().data('targetId', $pid);
                    $currComment.html(clones);
                }
                logit("# of comments on this paragraph " + localComments.size());
                jQuery("#show-current-comments .count").text(localComments.size());

            }
            $lastSelected = $pid;
        }
        $('.make-a-comment').unbind('click')
        $('.make-a-comment').click(function(event){
            event.preventDefault();
            $tabs.tabs('select', 2)
        })
        
    };

    // Set up tabs
    var $tabs = $("#tabcontainer").tabs({
        select: $selectCurrentTab
    });
        
    if (opts['hide_comments']) {
        $comments.hide();
    }

    // links in comments back to paragraphs; install a close handler
    jQuery("a.ctop").live('click',function(evt) { $comments.dialog('close');});

    jQuery("a[rel=displayComments]").live('click',
    function(evt) {
        evt.preventDefault();
        showForm();
        return false;
    });

    function handleForm(data, textStatus) {
        $theForm[0].reset();
        $comments.dialog('close');

        if (!data.approved) {
            jQuery.jGrowl("Your comment has been received, but it's waiting for administrator approval before it shows up on the site",
            {
                header: 'Thank You',
                sticky: true
            });
            return;
        }
        jQuery.jGrowl("Thanks for your comment.", {
            header: 'Comment Received',
            life: 7500
        });

        var newComment = jQuery(data.rendered);
        if (data.target != "") {
            newComment.addClass(data.target);
        }

        var commentDiv = jQuery("#all-comments").append(newComment);
        if (data.target != "") {
            $currComment.append(newComment.clone());
            var pCounter = jQuery("#" + data.target + " span.count");
            pCounter.text(parseInt(pCounter.text()) + 1);

        }
        updateCommentCounts(data.target ? ("#" + data.target) : null);

    }

    function handleError(xhr, textStatus, errorThrown) {
        jQuery.jGrowl(textStatus, {
            header: "Comment Submission Failed"
        });
        return false;
    }

    $theForm.submit(
        function(evt) {
            try {
                // need to have tinyMCE populate the actual form field
                tinyMCE.triggerSave();
                var postVars = $(this).serialize();
                jQuery.jGrowl("Submitting comment ...", {
                    'header': "Please Wait"
                });
                var theURL = $(this).attr('action');
                //$("input[type=submit]", this).attr("disabled", "disabled");
                jQuery.ajax({
                    url: theURL,
                    type: 'POST',
                    data: postVars,
                    success: handleForm,
                    error: handleError,
                    dataType: 'json'
                });
            } catch(e) {
                return confirm(e);
            }
            return false;
        }
    );

    $comments.dialog({
        open: function() {
            jQuery("textarea", $theForm).each(function() {
                initTinyMCE();
                tinyMCE.execCommand('mceAddControl', false, $(this).attr('id'));
            });
            $('body').css('overflow', 'hidden');
            $('body').css('overflow-x', 'scroll');
            $(window).trigger('resize');
        },
        close: function(){
            $('body').css('overflow', 'auto')
        },
        resizeStop: resizeDialogContents,
        resize: function(){logit('dialog resize event')},
        width: 900,
        minWidth: 500,
        height: calcDialogHeight(),
        minHeight: 500, 
        autoOpen: false,
        title: 'Comments',
        position: 'center',
        modal: true
    });
    
    function calcDialogHeight(){
        return $(window).height() - 100;
    }
    
    function calcTabsPanelHeight(){
        var tabHeight = $comments.dialog('option', 'height') - 120;
        return tabHeight;
    }
    
    function resizeDialogContents(){
        $('.ui-tabs-panel').height(calcTabsPanelHeight())
    }

    $(window).resize( function(){
    $comments.dialog('option', 'height', calcDialogHeight());
    $comments.dialog('option', 'position', 'center');
      resizeDialogContents();
    } )
    
    $('.ui-tabs-panel').height(calcTabsPanelHeight())
    
    function showForm(source) {
        if (source) {
            $targetParagraph.val(source.attr('id'));
            jQuery("p[id]", source.parent()).removeClass("active");
            source.addClass("active");
        }
        if ($comments.dialog('isOpen')) {
            $comments.dialog('close')
        }
        if (!$comments.dialog('isOpen')) {
            $comments.dialog('open');
        }
        if (source) {
            jQuery("#show-current-comments").click();
        }
        $selectCurrentTab({},
        {
            'index': source ? 1: 0
        });
        // need to remove the tinyMCE 'control' on close, because otherwise
        // the dialog is only good for one 'open' on a pageview.
        $comments.dialog('option', 'beforeclose',
        function() {
            if (source) {
                source.removeClass('active');
            }
            jQuery("textarea", opts.form).each(function() {
                tinyMCE.execCommand('mceRemoveControl', false, $(this).attr('id'));
            });
        });
    }

    return this;
}


/**
 * Adds the 'hover over footnote reference' behavior that shows the footnote.
 **/
jQuery.fn.footnotes = function(options) {

    /* these aren't used but they're ideas for how this might be extended 
   * and customized -- e.g. where to show the notes, how long to wait after mouse out to
   * hide, and perhaps whether to show the note until an explicit close (e.g. allow users to click
   * on links in notes **/

    var defaults = {
        position: 'bottom',
        hide_delay: 1000
    };
    var opts = jQuery.extend(defaults, options);

    var noteDisplay = jQuery("<div id='noteDisplay'/>");
    var container = jQuery("#content-wrapper");
    container.append(noteDisplay);

    var bodyWidth = container.width();

    noteDisplay.css({
        width: bodyWidth,
        minHeight: '3em',
        maxHeight: '10em',
        padding: '.2em'
    });

    this.each(function() {
        var noteref = $(this);
        var showNote = function() {
            var note = jQuery(".inline-note", noteref);
            noteDisplay.html(note.html());
            if (!noteDisplay.is(":visible")) {
                noteDisplay.fadeIn('fast');
            }
        };

        var hideNote = function() {
            //noteDisplay.animate({opacity:'100%'}, opts.hide_delay);
            noteDisplay.fadeOut('fast');
        };
        noteref.hoverIntent(showNote, hideNote);
    });

    return this;
}

/**
 * Adds hover effect over page break markers, showing where in the text the break
   occurs.  Also adds hover effects to paragraphs, showing (clickable) pilcrow marks
  on hover.
**/
jQuery.fn.paragraphLinks = function(opts) {
    jQuery("span.pagenum").each(
    function() {
        var $p = jQuery(this);
        var $num = $p.text();
        var $id = $p.attr('id');
        $p.html("<a href='#" + $id + "'><span>" + $num + "</span></a>");
        var $pbDisp = "span.pb-display[rel='" + $id + "']";

        $p.hoverIntent(function() {
            jQuery($pbDisp).show();
        },
        function() {
            jQuery($pbDisp).hide();
        }
        ).before("<span class='pb-display' rel='" + $id + "'> </span>");
    });

    jQuery("p[id]", this).each(function() {
        $(this).append('<a class="plink" href="#' + $(this).attr('id') + '">¶</a>');
    }).hoverIntent(
    function() {
        $("a.plink", this).css('visibility', 'visible');
    },
    function() {
        $("a.plink", this).css('visibility', 'hidden');
    });

    return this;
}

/**
 * Turns elements into a 'disclosure panel': click on the link to show, click again to hide.
 * sample use is user profile page editing form (only shown when you're on your own profile page).
 * 
 * options:
 * title: text of link to show panel when it is closed.
 * showingTitle: text of link to hide panel when it is open
 * initial: inital state, 'hidden' by default (anything else means shown)
 * effect: (string) name of effect to use when showing.
 *
 * beforeShow: function to execute before opening the panel
 * beforeHide: "" closing ""
 * afterShow: function to execute immediately after opening the panel
 * afterHide: "" closing ""
 * defaults for all callbacks is nop
 **/
jQuery.fn.disclosure = function(opts) {
    var defaults = {
        title: "Show",
        showingTitle: "Hide",
        initial: 'hidden',
        effect: 'slide',
        beforeShow: function() {},
        afterShow: function() {},
        beforeHide: function() {},
        afterHide: function() {}
    };

    var options = jQuery.extend(defaults, opts);
    var discloser = jQuery("<a href='#' class='disclosure-closed'></a>");
    var target = this;
    if (options.initial == 'hidden') {
        target.hide();
        discloser.text(options.title);
    } else {
        target.show();
        discloser.text(options.showingTitle);
    }

    discloser.insertBefore(this);
    discloser.click(function(evt) {
        evt.preventDefault();
        var isVisible = target.is(":visible");
        if (!isVisible) {
            options.beforeShow(evt, this);
            discloser.text(options.showingTitle);
            target.show(options.effect).children("*").show();
            options.afterShow(this);
        } else {
            options.beforeHide(this);
            discloser.text(options.title);
            target.hide(options.effect);
            options.afterHide(this);
        }
        discloser.toggleClass('disclosure-closed').toggleClass('disclosure-open');
    });
    return this;
}

/**
 * "Cite this work" function, implements a a bit of what disclosure plugin does, and should probably be dumped in favour
 * of that, but here it is anyhow.
 **/
jQuery.fn.citation = function(url) {
    var cite = this;
    this.hide();
    var loaded = false;
    var citeLink = jQuery("<a href='#' class='disclosure-closed'>Cite This Work</a>");
    citeLink.insertBefore(cite);
    citeLink.click(function(evt) {
        evt.preventDefault();
        if (!loaded) {
            jQuery.get(url,
            function(data, resultText) {
                cite.html(data);
                loaded = true;
            });
        }
        citeLink.toggleClass("disclosure-closed").toggleClass("disclosure-open");
        cite.toggle();
    });
    return this;
  return this;
}


/**
 * Despite our best styling efforts, some elements like to overflow the boundaries
 * of their container; managing that with CSS overflow doesn't necessarily produce
 * the best results.  This plugin attempts to shrink the fonts on "too wide" tables
 * (a common culprit) down so they fit in the container.
 **/
jQuery.fn.containChildren = function() {
    var wrapper = this;
    /*
	wrapper.children().each( function() {
		if (jQuery(this).height() > wrapper.height() ) {
				wrapper.height( jQuery(this).height() );
		}
	});
	var footerOffset = jQuery("#footer").offset();
	if ( footerOffset.top < wrapper.offset().top + wrapper.height() ) {
		jQuery("#footer").css( 'top' , wrapper.offset().top + wrapper.height() + 1 );
	}
 */
    var contentRight = wrapper.offset().left + wrapper.width();
    $("#main table").each(function() {
        var rightOffset = $(this).offset().left + $(this).width();
        if (rightOffset > contentRight) {
            var diff = rightOffset - contentRight;
            var newWidth = $(this).width() - diff - 45;
            var ratio = newWidth / $(this).width();
            $("tr", this).css("font-size", ratio + "em");
        }
    });
    return this;
};
