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
            $(this).addClass('annotation-target')
            var paragraph = $(this);
            var pid = paragraph.attr('id');
            var myComments = jQuery("." + pid, opts['comments']);
            var $hook = jQuery("<div class='commentCount " + opts['hook_class'] + (myComments.size() == 0 ? ' hidden': '') + "'><span class='count'>" + myComments.size() + "</span></div>");
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
        filtered: false,
        targetParagraph: null,
        lastTarget: null,
        getTargetParagraph: function(){
            return this.targetParagraph;
        },
        setTargetParagraph: function(targetParagraph){
            this.lastTarget = this.targetParagraph;
            this.targetParagraph = $(targetParagraph)
            this.filterComments(this.targetParagraph);
            this.displaySource(this.targetParagraph);
            this.element.trigger({type: 'targetChange', targetParagraph: this.targetParagraph})
            if(this.targetParagraph != null){
                $('#all-comments').text('Show All Annotations');
            }
        },
        _original_init: $.ui.dialog.prototype._init,
        _init: function(){
            self = this;
            self._original_init()
            self.setTargetParagraph($('.annotation-target').first());
            self.element.bind('targetChange', function(){
                self.scrollToTop();
    		})
    		$('#previous-paragraph').click(function(evt){
    			evt.preventDefault()
    		 	self.previousParagraph();
    		})
    		$('#next-paragraph').click(function(evt){
    			evt.preventDefault()
    		 	self.nextParagraph();
    		})
    		$('#all-comments').click(function(evt){
    			// Move this into the dialog class
    			evt.preventDefault();
    			if(self.filtered){
    				self.showAllComments();
                    self.scrollToTop();
    			}else{
    				self.setTargetParagraph(self.lastTarget);
    			}
    		})
    		$('#make-comment').click(function(evt){
    			commentFormTop = Math.round($('#comment-form').position().top + $('#comment-column').scrollTop())
                $('#comment-column').animate({scrollTop: commentFormTop}, {duration: 500, complete: function(){$('#comment-form').annotationForm('reset');$('#comment-form').annotationForm('focus');} })
    		})
    		
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
            $('#previous-paragraph, #next-paragraph').show();
            $('.'+$(targetParagraph).attr('id')).show();
            this.filtered = true
        },
        displaySource: function(targetParagraph){
            $('#source-paragraph').show()
            $targetClone = $(targetParagraph).clone()
            $('.annotation-hook', $targetClone).remove()
            $targetContent = $targetClone.html();

            $('#source-paragraph .source').html($targetContent)
        },
        showAllComments: function(){
            this.setTargetParagraph(null);
            $('.comment').show();
            $('#source-paragraph').hide();
            $('#comment-column').css({width: '100%'})
            $('#previous-paragraph, #next-paragraph').hide();
            this.filtered = false;
			$('#all-comments').text('Back to Paragraph Annotations');
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
            previousParagraph = this.targetParagraph.prevAll('p').first();
            if(previousParagraph.length > 0){
                this.setTargetParagraph(previousParagraph)
            }
            return this.targetParagraph;
        },
        nextParagraph: function(){
            nextParagraph = this.targetParagraph.nextAll('p').first();
            if(nextParagraph.length > 0){
                this.setTargetParagraph(nextParagraph)
            }
            return this.targetParagraph;
        },
        scrollToTop: function(){
            $('#comment-column').animate({scrollTop: 0}, {duration: 100});
			$('#source-paragraph').animate({scrollTop: 0}, {duration: 100});
        }
    };
    $("p[id]").not("blockquote p[id]").not("div.figure p[id]")
    $.widget ('ui.annotationDialog', $.extend({},$.ui.dialog.prototype, dialogExt));

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
                $targetParagraph = $(targetParagraph)
                if($targetParagraph.size() > 0){
                    $('#id_content_internal_path').val($targetParagraph.attr('id'))
                }else{
                    $('#id_content_internal_path').val(null)
                }
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
