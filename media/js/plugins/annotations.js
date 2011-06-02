/**
* Finds all the possible targets of comments in the current page
            * and prepares them.
**/
(function( $ ){

    jQuery.fn.prepareCommentTargets = function(options) {
        var defaults = {
            comments: jQuery("#comments-dialog"),
            hook_class: "annotation-hook",
            internal_path_id: "id_content_internal_path"
        };

        var opts = jQuery.extend(defaults, options);

        this.each(function() {
            // note 'this' is now an individual paragraph
            var paragraph = $(this);
            var pid = paragraph.attr('id');
            var myComments = jQuery("." + pid, opts['comments']);
            var $hook = jQuery("<div class='" + opts['hook_class'] + (myComments.size() == 0 ? ' hidden': '') + "'><span class='count'>" + myComments.size() + "</span></div>");
            paragraph.data('comments', myComments).prepend($hook);
            return this;
        });

        return this;
    };
})(jQuery);


// Jquery UI dialog extension //
(function( $ ){
    dialogExt = {
        commentColWidth: $('#commentsColumn').width(),
        targetParagraph: null,
        getTargetParagraph: function(){
            return this.$targetParagraph;
        },
        setTargetParagraph: function(targetParagraph){
            this.$targetParagraph = $(targetParagraph)
            this.filterComments(this.$targetParagraph);
            this.displaySource(this.$targetParagraph);
        },
        _filtered: false,
        filtered: function(){
            return this._filtered;
        },
        _original_init: $.ui.dialog.prototype._init,
        _init: function(){
            this._original_init()
        },
        _original_open: $.ui.dialog.prototype.open,
        open: function(targetParagraph){
            //TODO: on open prevent scrolling
            if(targetParagraph){
                this.setTargetParagraph(targetParagraph);
            }else{
                this.showAllComments();
            }
            
            this._original_open();
            this.freezeScrolling();
        },
        _original_close: $.ui.dialog.prototype.close,
        close: function(){
            this._original_close()
            this.releaseScrolling();
        },
        filterComments: function(targetParagraph){
            $('#comment-column').css({width: this.commentColWidth})
            $('.comment').hide();
            $('.'+$(targetParagraph).attr('id')).show();
            this._filtered = true
        },
        displaySource: function(targetParagraph){
            logit('displaySource')
            $('#source-paragraph').show()
            $targetClone = $(targetParagraph).clone()
            $('.annotation-hook', $targetClone).remove()
            $targetContent = $targetClone.html();

            $('#source-paragraph .source').html($targetContent)
        },
        showAllComments: function(){
            $('.comment').show();
            $('#source-paragraph').hide();
            $('#comment-column').css({width: '100%'})
            this._filtered = false;
        },
        freezeScrolling: function() {
            $('body').css('overflow', 'hidden');
            $('body').css('overflow-x', 'scroll');
            $(window).trigger('resize');
        },
        releaseScrolling: function(){
            $('body').css('overflow', 'auto');
        },
        previousParagraph: function(){
            logit('previousParagraph')
            previousParagraph = this.$targetParagraph.prevAll('p').first();
            if(previousParagraph.length > 0){
                this.setTargetParagraph(previousParagraph)
            }
            return this.$targetParagraph;
        },
        nextParagraph: function(){
            logit('nextParagraph')
            nextParagraph = this.$targetParagraph.nextAll('p').first();
            if(nextParagraph.length > 0){
                this.setTargetParagraph(nextParagraph)
            }
            return this.$targetParagraph;
        }
    };
    $("p[id]").not("blockquote p[id]").not("div.figure p[id]")
    //Figure out how to name this extended dialog differently
    $.extend($.ui.dialog.prototype, dialogExt)

})(jQuery);

// Annotation Form Behavior //
(function( $ ){
    methods = {
        init: function(options){
            return this.each(function(){
                $this = $(this)
                $textarea = jQuery('textarea', $this);
                initTinyMCE();
                tinyMCE.execCommand('mceAddControl', false, $textarea.attr('id'));

                $this.submit(function(evt){
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
                    evt.preventDefault();
                })
            })
        },
        destroy: function(){
            $textarea = jQuery('textarea', $this);
            tinyMCE.execCommand('mceRemoveControl', false, $textarea.attr('id'));
            $this.unbind('submit')
        },
        setTargetParagraph: function(targetParagraph){
            if(targetParagraph){
                $('#id_content_internal_path').val($(targetParagraph).attr('id'))
            }else{
                $('#id_content_internal_path').val('')
            }
        },
        focus: function(){
			tinyMCE.execInstanceCommand("id_comment", "mceFocus"); 
        },
        reset: function(){
            tinyMCE.execInstanceCommand("id_comment",'mceSetContent', false, ''); 
        }
    }
        
    handleForm = function (data, textStatus) {
        $('#comment-form')[0].reset();

        if (!data.approved) {
            jQuery.jGrowl("Your comment has been received, but it's waiting for administrator approval before it shows up on the site", { header: 'Thank You', sticky: true});
            return;
        }
        jQuery.jGrowl("Thanks for your comment.", {
            header: 'Comment Received',
            life: 7500
        });
        
        $this.trigger({type:'commentSuccess', targetParagraph: data.target, newComment: data.rendered});

    }

    handleError = function (xhr, textStatus, errorThrown) {
        logit('handleError')
        $this.trigger('commentError', [textStatus, errorThrown]);
        jQuery.jGrowl(textStatus, {
            header: "Comment Submission Failed"
        });
        return false;
    }
    
    jQuery.fn.annotationForm = function(method) {
        if ( methods[method] ) {
          return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
          return methods.init.apply( this, arguments );
        } else {
          $.error( 'Method ' +  method + ' does not exist on jQuery.tooltip' );
        }
        
                
    };

})(jQuery);
