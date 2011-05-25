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
        setUpForm: function() {
            jQuery("textarea", $theForm).each(function() {
                initTinyMCE();
                tinyMCE.execCommand('mceAddControl', false, $(this).attr('id'));
            });
        }
    };
    
    //Figure out how to name this extended dialog differently
    $.extend($.ui.dialog.prototype, dialogExt)

})(jQuery);


