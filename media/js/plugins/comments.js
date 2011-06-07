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

// function loadEditor(html) {
//     tinyMCE.activeEditor.setContent(html);
// }

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
    var $allCount = jQuery(".comments .comment").size();
    var $parCount = $('.comments .'+targetId).size();

    $(".sectionCount .count").text($allCount);
    $('#'+targetId + " .count").text($parCount);

    if($parCount > 0){
        $('p#'+targetId+" .annotation-hook").removeClass('hidden')
    }else{
        $('p#'+targetId+" .annotation-hook").addClass('hidden')
    }

    if($allCount > 0){
        $(".work-sections .section.current a").addClass('has-comments');
    }else{
        $(".work-sections .section.current a").removeClass('has-comments');
    }
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
