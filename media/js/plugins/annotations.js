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
        _original_init: $.ui.dialog.prototype._init, 
        _init: function(){
            this._original_init()
            logit('hello motherfucka!')
        },
        _original_open: $.ui.dialog.prototype.open,
        open: function(targetParagraph){
            //TODO: on open prevent scrolling
            if(targetParagraph){
                $('#source-paragraph').show()
                this.displaySource(targetParagraph);
                this.filterComments(targetParagraph);
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
        },
        displaySource: function(targetParagraph){
            $targetClone = $(targetParagraph).clone()
            $('.annotation-hook', $targetClone).remove()
            $targetContent = $targetClone.html();

            $('#source-paragraph .source').html($targetContent)
        },
        showAllComments: function(){
            $('.comment').show();
            $('#source-paragraph').hide();
            $('#comment-column').css({width: '100%'})
        },
        freezeScrolling: function() {
            $('body').css('overflow', 'hidden');
            $('body').css('overflow-x', 'scroll');
            $(window).trigger('resize');
        },
        releaseScrolling: function(){
            $('body').css('overflow', 'auto');
        },
    };
    
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
        setContentInternalPath: function(contentInternalPath){
            if(contentInternalPath){
                $('#id_content_internal_path').val(contentInternalPath)
            }else{
                $('#id_content_internal_path').val('')
            }
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
