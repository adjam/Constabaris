/* $Id$ */

/**
 * Turns an input box into an asynchronously powered
 * search box.
 * usage:
 * $(selector).workSearch({resultsTarget: '#search-results', url : '/path/to/search'});
 *  - both options are required.
 *  - search will be triggered onChange or on form submit
 * 
 */
jQuery.fn.workSearch = function(options) {
	var resultLocation = jQuery(options.resultsTarget);
	
	var successCallback = function(data) {
		if ( window.console ) {
			window.console.log("Search returned " + data, data.length);
		}
		if ( data.length == 0 ) {
			resultLocation.text("Search returned no results");
			return;
		}
		var resultList = jQuery("<ul/>");
		for( var i = 0; i < data.length; i++ ) {
			var result = data[i];
			var item = jQuery("<li><a href='/voice" + result.url + "'>" + result.title + "</a></li>");
			resultList.append(item);
		}
		var header = jQuery("<h3>Matching Sections (" + data.length + ")</h3>");
		
		resultLocation.html(header).append(resultList);
	};
	
	var errorCallback = function(xhr,errType,exc) {
		if ( exc ) {
			alert(exc);
		} else {
			alert("error type: " + errType );
		}
		resultsTarget.text("search failed");
	}; 
	
	function doSearch() {
		var queryText = jQuery(this).val();
		if ( queryText ) {
			resultLocation.text("Searching ...");
			jQuery.ajax({
				data: { query: queryText },
				url : options.url,
				dataType : 'json',
				success: successCallback,
				error : errorCallback
			});
		}
	};
	jQuery(this).change( doSearch );
	jQuery(this).closest('form').submit( function() {
		doSearch();
		return false;
		}
	);
	return this;	
};

/**
 * Fetches basic work info from a specified URL when an HTML <option>
 * element's value is changed.  Used to enhance the readout without making the 
 * drop down unwieldy.
 * OPTIONS (required)
 * - url : the base URL for the JSON service that fetches info about works.
 * - resultsTarget : a selector that matches the DOM element where the results
                     will be sent after the AJAX call.
 **/                     
jQuery.fn.enhanceWorkInfo = function(options) {
	var queryURL = options.url;
	var resultsTarget = jQuery(options.resultsTarget);
	var widget = jQuery(this);
	widget.change( function(evt) {
		var theURL = options.url + widget.val();
		jQuery.ajax({
			url: theURL,
			dataType : 'json',
			beforeSend : function() {
				if ( resultsTarget.not(":visible") ) {
					resultsTarget.show();
				}
				resultsTarget.fadeTo(0.1);
			},
			success : function(data) {
					var result = data[0].fields;
					var genre = data[1].fields;
					var html = "<h3> " + result.title +"</h3><ul>"
					+ "<li><b>Genre</b>: " + genre.label + "</li>" 
					+ "<li><b>ISBN</b>: " + ( result.isbn ? result.isbn : '----' ) + "</li>" 
					+ "<li><b>Author</b>: " + result.author_display + "</li>"
					+ "</ul>";
					resultsTarget.html(html);
					resultsTarget.fadeTo(1.0);
			},
			error : function(xhr,errType,exc) {
				alert("Error: " + errType + ":" + exc);
			}
		}); 
	});	
	return this;
};
