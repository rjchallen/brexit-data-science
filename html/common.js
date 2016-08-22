function componentToHex(c) {
	    var hex = Math.floor(c).toString(16);
	    return hex.length == 1 ? "0" + hex : hex;
	}

function rgbToHex(r, g, b) {
    return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
}
	
function format(d) {
	return parseFloat(d).toFixed(1)+"%";
}
// (+/-"+parseFloat(d.weighted_confidence).toFixed(1)+"%)"};
