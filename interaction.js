/**
Test cmd:

phantomjs --local-to-remote-url-access=yes rasterize.js "[URL]" 
"./junk.png" "./junk.html" "./junk.missing"

phantomjs --local-to-remote-url-access=yes rasterize.js "http://192.168.1.7/mementoImportance/www.cs.odu.edu/" 
"./csjunk.png" "./csjunk.html" "./csjunk.missing"
/**/

var fs = require('fs');
var server = require('webserver').create();
var theresources = [];
var index = 0;
var thecodes = [];
var theurls = [];

var page = require('webpage').create(),
    address, output, size;

if (phantom.args.length < 4 || phantom.args.length > 4) {
    console.log('Usage: interaction.js URL httpLogFile htmlFile interactionFile');
    phantom.exit();
} else {
    	address = phantom.args[0];
    	httpOutput = phantom.args[1];
    	htmlOutput = phantom.args[2];
    	interactionOutput = phantom.args[3];

	//fs.write(httpOutput, address, "w");

    	page.viewportSize = { width: 1024, height: 777 }; 
    	//page.viewportSize = { width: 600, height: 600 };

	//create the file
	console.log("writing 1");
	fs.write(httpOutput, "", "w");
	fs.write(htmlOutput, "", "w");
	fs.write(interactionOutput, "", "w");


	/**header monitoring**/
	page.onResourceReceived = function (res) {
		theresources[res.url] = res.url;
		//console.log("Response " + res.id + ", " + res.url);
		
		fs.write(phantom.args[1], (res.status + ", " + res.url + "\n"), "a");
		console.log("writing 2: " + res.status + ", " +  res.url);
	    };

	//page.onResourceReceived = function(response) {
	//    console.log('Response (#' + response.id + ', stage "' + response.stage + '"): ' + JSON.stringify(response));
	//};




    page.open(address, function (status) {

        if (status !== 'success') {
            console.log('Unable to load the address!');
    	    phantom.exit();
        } else {

		/** this is new...**/
		page.injectJs("http://code.jquery.com/jquery-1.9.1.js");
		page.injectJs("https://raw.github.com/douglascrockford/JSON-js/master/json2.js");

            window.setTimeout(function () {
		//console.log("written to " + output + "\n\n");
                page.render(output);

		var pageContent = page.evaluate(function() { 
		    var content = document.body.parentElement.outerHTML; 
		    return content;
		});


		/////////////////////////////////////////////////////////

		var sizeArr = page.evaluate(function () {
		     var pageWidth = document.body.clientWidth;
		     var pageHeight = document.body.clientHeight;

		     return [pageWidth, pageHeight];
		  });

		console.log("My viewport is " + sizeArr);

		//fs.write(phantom.args[1], address, "w");
		var theThings = page.evaluate(function () {
			var targets = Array();
			var elems = document.getElementsByTagName('*');
			/**This method tests against all interactive properties**
			for (var i = 0; i < elems.length; i++) {
				var theProps = [
				"onabort",
				"onblur",
				"onchange",
				"onclick",
				"ondblclick",
				"onerror",
				"onfocus",
				"onkeydown",
				"onkeypress",
				"onkeyup",
				"onload",
				"onmousedown",
				"onmousemove",
				"onmouseout",
				"onmouseover",
				"onmouseup",
				"onreset",
				"onresize",
				"onselect",
				"onsubmit",
				"onunload"
				];
				for(var j = 0; j < theProps.length; j++)
				{
					if (elems[i].hasOwnProperty(theProps[j])) { 
						//var thePushed = JSON.stringify(elems[i], "", 2);
						//var thePushed = $(this).toJSON(elems[i], null, 2);
						var thePushed = elems[i].innerHTML + " <!-- " + theProps[j] + " -->";
						//var thePushed = "Hi justin";
						targets.push(thePushed);
						//targets.push(theProps[j]);
					}
				}
				//targets.push(elems[i].id);
			}
			/**/

			console.log("Hi1")

			/**This method looks at responses to on* fired events**/
			for (var i = 0; i < elems.length; i++) {
				//list of attributes: http://www.w3schools.com/tags/ref_eventattributes.asp
				var theProps = [
					"onclick"
					];

				for(var j = 0; j < theProps.length; j++)
				{
					if (elems[i].hasAttribute(theProps[j])) { 
						//var thePushed = JSON.stringify(elems[i], "", 2);
						//var thePushed = $(this).toJSON(elems[i], null, 2);
						var thePushed = elems[i].outerHTML + " <!-- " + theProps[j] + " -->";
						//var thePushed = "Hi justin";
						//targets.push(thePushed);
						targets.push(theProps[j] + ", " + thePushed);
					}
				}
			}
			/**/


			return targets;
		});

		console.log("DONE");

		var thecount = 0;
		for (var i = 0; i < theThings.length; i++) {
			//if(isInteractive(theThings[i]))
			//{
				//console.log(theThings[i] + " is interactive");
				thecount++;
				console.log("writing 3");
				fs.write(phantom.args[3], (theThings[i] + "\n"), "a");
			//}
		}

		console.log("I have a length of things: " + theThings.length + " interactive things\n");
		console.log("I have " + thecount + " interactive things\n");
		
		/////////////////////////////////////////////////////////


		var pageContent = page.evaluate(function() { 
		    var content = document.body.parentElement.outerHTML; 
		    return content;
		    //console.log("content written");
		});


		console.log("writing 4");
		fs.write(htmlOutput, pageContent, "w");
		
                phantom.exit();
            }, 200);
        }
    });

}


function findPos(obj) {
        var curleft = curtop = 0;
        if (obj.offsetParent) {
		do {
		                curleft += obj.offsetLeft;
		                curtop += obj.offsetTop;
		} while (obj = obj.offsetParent);
        	return [curleft,curtop];
	}
}

/**/
function getNumTags(tagName)
{
	var num = page.evaluate(function(tagName) {
	    return document.getElementsByTagName(tagName).length;
	}, tagName);

	return num;
}
function getNumClass(tagName, content)
{
	var num = page.evaluate(function(tagName) {
		/**/
		var counter = 0;
		var elems = document.getElementsByTagName('*');
		for (var i = 0; i < elems.length; i++) {
			if((' ' + elems[i].className + ' ').indexOf(' ' + tagName + ' ') > -1) 
			{
				counter++;
			}
		}
		/**/
		return counter;
	}, tagName);

	return num;
}

function isInteractive(obj)
{
	// from http://blogs.telerik.com/aspnet-ajax/posts/09-02-27/client---side-events-in-javascript.aspx
	var theProps = [
			"onabort",
			"onblur",
			"onchange",
			"onclick",
			"ondblclick",
			"onerror",
			"onfocus",
			"onkeydown",
			"onkeypress",
			"onkeyup",
			"onload",
			"onmousedown",
			"onmousemove",
			"onmouseout",
			"onmouseover",
			"onmouseup",
			"onreset",
			"onresize",
			"onselect",
			"onsubmit",
			"onunload"
			];
	for(var i = 0; i < theProps.length; i++)
	{
		if (obj.hasOwnProperty(theProps[i])) { 
			return true;
		}
	}
	return false
}

function getNumTagByClass(tagName, styleName, content)
{
	var num = page.evaluate(function(tagName, styleName) {
		/**/
		var counter = 0;
		var elems = document.getElementsByTagName(tagName);
		for (var i = 0; i < elems.length; i++) {
			if((' ' + elems[i].className + ' ').indexOf(' ' + styleName + ' ') > -1) 
			{
				counter++;
			}
		}
		/**/
		return counter;
	}, tagName, styleName);

	return num;
}
function getNumID(tagName)
{
	var num = page.evaluate(function(tagName) {
	    var theThing = document.getElementById(tagName);
	    if(theThing == null)
		return 0;
	    return 1;
	}, tagName);

	return num;
}
/**/

function getAllClasses(content)
{
	var num = page.evaluate(function() {
		/**/
		var myClasses = Array();
		var elems = document.getElementsByTagName('*');
		for (var i = 0; i < elems.length; i++) {
			if((elems[i].className == "") || (elems[i].className == null))
			{
				//do nothing
			}
			else
			{
				myClasses.push(elems[i].className);
			}
		}
		/**/
		return myClasses;
	});

	return num;
}

