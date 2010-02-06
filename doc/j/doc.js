$(document).ready(function() {
showTOC();

function showTOC() {
    var toc = '';
    var old_level = 1;
    $('h2,h3').each(function(i, h) {
	    level = parseInt(h.tagName.substring(1));
	    if (level < old_level) {
		toc += '</ol>';
	    } else if (level > old_level) {
		toc += '<ol>';
	    }
	    toc += '<li><a href=#' + h.id + '>' + h.innerHTML + '</a>';
	    old_level = level;
	});
    while (level > 1) {
	toc += '</ol>';
	level -= 1;
    }
    toc = '<ol start=1>' + toc.substring(4);
    $("#toc").html(toc);
}

});