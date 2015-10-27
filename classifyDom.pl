use HTML::TagParser;
use URI::URL;
use List::Util qw[min max];

#classifying deffered representations:
#=====================================
#this perl file creates the feature vector for
# use in Weka to classify a deferred representation
#This generates raw data only, not performing
# the classification.


### need to find on* events
### need to look for ajax.get() and XMLHttpRequest


##run interaction.js
###this gets us the events 
###then read the html file for ajax requests
###will likely need to read embedded JS for this too

###interactive guys:
my @interactiveGuys = (
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
);

if($#ARGV < 1 || $#ARGV > 1)
{
	print "USAGE: perl classifyDOM.pl <URI>\n";
	exit();
}

my $uri = $ARGV[0];
my $pref = $ARGV[1];
my $logfile = "logfile";
my $htmlfile = "htmlfile";
my $interactionfile = "interactionfile";
my $junkFile = "junkJS.js";

my @adList;


###sample command
###phantomjs interaction.js http://www.cs.odu.edu/ jnklog htmlFile
#my $cmd = "phantomjs interaction.js \"$uri\" $logfile $htmlfile $interactionfile";
#my $cmd = "/var/www/phantomjs/bin/phantomjs interaction.js \"$uri\" $logfile $htmlfile $interactionfile";
my $cmd = "phantomjs interaction.js \"$uri\" $logfile $htmlfile $interactionfile";

print "Running...$cmd\n\n";
my @results = `$cmd`;
print "done!\n";

open(FILE, $logfile);
my @embeddedGuys = <FILE>;
close(FILE);

open(FILE, $htmlfile);
my @content = <FILE>;
close(FILE);

open(FILE, $interactionfile);
my @events = <FILE>;
close(FILE);

my $dom = join(/\n/, @content);

my $contentSize = $#content+1;

my $CssGuys = "";

##########Find 
#my $cmd = "curl -s -o hosts \"http://pgl.yoyo.org/as/serverlist.php?showintro=0;hostformat=hosts\"";
#my $c = `$cmd`;

open(IN, "hosts");
@adList = <IN>;
close(IN);
my $adThing = "";


#raw
my $numAds = 0;
my $numJS  = 0;
my $numInteractive = max(0, $#events+1);
my $numFoundSame = 0;
my $numFoundDiff = 0;
my $numMissedSame = 0;
my $numMissedDiff = 0;
my $interactiveJSguys = 0;
my $numFoundJS = 0;
my $numFoundHTML = 0;
my $numMissedJS = 0;
my $numMissedHTML = 0;
my $interactiveHTML = 0;

##new ones: 2014/06/16
my $numDomMods = 0;
my $jsNav = 0;
my $jsCookies = 0;

for(my $i = 0; $i < $#embeddedGuys+1; $i++)
{
	my $line = trim($embeddedGuys[$i]);
	my @arr = split(/, /, $line);
	my $code = trim($arr[0]);
	my $resource = trim($arr[1]);

	if($resource =~ m/\.css/ig)
	{
		my $CssGuys += $resource . "\n";
	}
	
	for(my $j = 0; $j < $#adList+1; $j++)
	{
		my $home = "127.0.0.1";
		$adThing = trim($adList[$j]);
		$adThing =~ s/$home//i;
		$adThing = trim($adThing);

		#print "$adThing ==> " . index($resource, $adThing) . "\n";

		if(index($resource, $adThing) != -1)
		{
			#print "$resource vs: $adThing!\n";
			$numAds++;
		}
	}
}

my $c = () = $dom =~ /<script/ig;
$c++;
$numJS = $c;

############################################
#finding local/remote stuff
############################################
my $thisURL = new URI::URL $uri;
my $domain = $thisURL->host;

print "Host: $domain\n";

for(my $i = 0; $i < $#embeddedGuys+1; $i++)
{
	my $line = trim($embeddedGuys[$i]);
	my @arr = split(/, /, $line);
	my $code = trim($arr[0]);
	my $resource = trim($arr[1]);

	if($code == 200)
	{
		if(isSame($resource, $domain) == 1)
		{
			#print ("$resource is same as $uri\n");
			$numFoundSame++;
		}
		else
		{
			#print ("$resource is diff than $uri\n");
			$numFoundDiff++;
		}

		if(isHTML($dom, $resource, $CssGuys))
		{
			$numFoundHTML++;
		}
		else
		{
			$numFoundJS++;
		}
	}
	elsif($cod =~ m/^3../)
	{
		##300, do nothing
	}
	else
	{
		if(isSame($resource, $domain) == 1)
		{
			#print ("$resource is same as $uri\n");
			$numFoundSame++;
		}
		else
		{
			#print ("$resource is diff than $uri\n");
			$numFoundDiff++;
		}

		if(isHTML($dom, $resource, $CssGuys))
		{
			$numMissedHTML++;
		}
		else
		{
			$numMissedJS++;
		}
	}
}



############################################
#finding ajax stuff
############################################

my $ajaxStr = "ajax\\.get";
my $ajaxStr2 = "\\.ajax\\(";
my $httpStr = "XMLHttpRequest";

if($dom =~ m/$ajaxStr/ig)
{
	my $c = () = $dom =~ /$ajaxStr/ig;
	$c++;
	$interactiveHTML += $c;
	#print "AJAX in html $c times\n";
}
if($dom =~ m/$httpStr/ig)
{
	my $c = () = $dom =~ /$httpStr/ig;
	$c++;
	$interactiveHTML += $c;
	#print "HTTPReq in html $c times\n";
}


############################################
#finding dom mod stuff
############################################

my $domMod1 = "\\.write\\(";
my $domMod2 = "\\.create";
my $domMod3 = "\\.appendChild";
my $domMod4 = "\\.removeChild";
my $domMod5 = "\\.replaceChild";
my $domMod6 = "\\.insertBefore";
my $domMod7 = "\\.insertAfter";
my $domMod8 = "\\.innerHTML=";
my $domMod9 = "\\.innerHTML =";
my $domMod10 = "\\.attribute=";
my $domMod11 = "\\.attribute =";
my $domMod12 = "\\.src=";
my $domMod13 = "\\.src =";

if($dom =~ m/$domMod1/ig)
{
	my $c = () = $dom =~ /$domMod1/ig;
	$c++;
	$numDomMods += $c;
	#print "AJAX in html $c times\n";
}
if($dom =~ m/$domMod2/ig)
{
	my $c = () = $dom =~ /$domMod2/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod3/ig)
{
	my $c = () = $dom =~ /$domMod3/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod4/ig)
{
	my $c = () = $dom =~ /$domMod4/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod5/ig)
{
	my $c = () = $dom =~ /$domMod5/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod6/ig)
{
	my $c = () = $dom =~ /$domMod6/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod7/ig)
{
	my $c = () = $dom =~ /$domMod7/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod8/ig)
{
	my $c = () = $dom =~ /$domMod9/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod10/ig)
{
	my $c = () = $dom =~ /$domMod10/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod11/ig)
{
	my $c = () = $dom =~ /$domMod11/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod12/ig)
{
	my $c = () = $dom =~ /$domMod12/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$domMod13/ig)
{
	my $c = () = $dom =~ /$domMod13/ig;
	$c++;
	$numDomMods += $c;
	#print "HTTPReq in html $c times\n";
}



my $nav1 = "\\.history\\.";
my $nav2 = "navigator\\.";
my $nav3 = "\\.history\\. =";
if($dom =~ m/$nav1/ig)
{
	my $c = () = $dom =~ /$nav1/ig;
	$c++;
	$jsNav += $c
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$nav2/ig)
{
	my $c = () = $dom =~ /$nav2/ig;
	$c++;
	$jsNav += $c
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$nav3/ig)
{
	my $c = () = $dom =~ /$nav3/ig;
	$c++;
	$jsNav += $c
	#print "HTTPReq in html $c times\n";
}


my $cookie1 = "\\.cookie=";
my $cookie2 = "\\.cookie =";
if($dom =~ m/$cookie1/ig)
{
	my $c = () = $dom =~ /$cookie1/ig;
	$c++;
	$jsCookies += $c
	#print "HTTPReq in html $c times\n";
}
if($dom =~ m/$cookie2/ig)
{
	my $c = () = $dom =~ /$cookie2/ig;
	$c++;
	$jsCookies += $c
	#print "HTTPReq in html $c times\n";
}

#print "So far, we have $numInteractive interactive elements, $interactiveHTML AJAX in html, and $interactiveHTML HTTPReq in html\n";
#sleep(10);

my $html = HTML::TagParser->new( $dom );
my @list = $html->getElementsByTagName( "script" );

open(JNK, ">$junkFile");

for my $l (@list)
{
	#type="text/javascript" src="//www.google.com/jsapi"
	my $tagname = $l->tagName;
        my $type = $l->getAttribute("type");
        my $lang = $l->getAttribute("language");
	my $loc = $l->getAttribute("src");
        my $text = $l->innerText;

	my $fqdn = "";

	#print "finding $text ==> $loc\n";

	if(($type || $lang) && $loc)
	{
		if($type =~ /java/ig || $lang =~ /java/ig)
		{
			#print "Scripties: $type ==> $loc\n";
			my $url = new URI::URL $uri;
			my $jsfile = new URI::URL ($uri . $loc);
			#my $host = "http://" . $url->host . "/" . $url->path . "/";
			if($loc =~ /^http:\/\//i)
			{
				$fqdn = $loc;
			}
			else
			{
				$fqdn = $jsfile->abs($jsfile);
			}
			print "curling: $fqdn\n";

			my @jscode = `curl -s "$fqdn"`;
			my $jscont = join("\n", @jscode);

			print JNK $jscont . "\n\n\n\n\n\n";

			if(1)
			{
				if($jscont =~ m/$ajaxStr/ig)
				{
					my $c = () = $jscont =~ /$ajaxStr/ig;
					$c++;
					$interactiveJSguys += $c;
					#print "AJAX.GET in code $c times\n";
				}
				if($jscont =~ m/$ajaxStr2/ig)
				{
					my $c = () = $jscont =~ /$ajaxStr2/ig;
					$c++;
					$interactiveJSguys += $c;
					#print ".AJAX in code $c times\n";
				}

				if($jscont =~ m/$httpStr/ig)
				{
					my $c = () = $jscont =~ /$httpStr/ig;
					$c++;
					$interactiveJSguys += $c;
					#print "HTTPRequest in code $c times\n";
				}
			}
		}
	}
}

close(JNK);


my $numDomMods = 0;
my $jsNav = 0;
my $jsCookies = 0;

open(OUT, ">>$pref" . "domClassification.csv");
#print "URIR, Deferred?, #Ads, #JS, #Interactive, #Ajax from JS, #Ajax from HTML, #Found Same, #Found Diff, #Missed Same, #Missed Diff\n";
print OUT "$numAds, $numJS, $numInteractive, $interactiveJSguys, $interactiveHTML, $numFoundSame, "
	. "$numFoundDiff, $numMissedSame, $numMissedDiff"
	## new guys
	. "$numDomMods, $jsNav, $jsCookies\n";

print "$numAds ads\n";
print "$numJS embedded JS sections\n";
print "$numInteractive interactive elements on page\n";
print "$interactiveJSguys ajax requests in the JavaScript\n";
print "$interactiveHTML ajax requests in the html\n\n";

print "Found Same $numFoundSame\n";
print "Found Diff $numFoundDiff\n";
print "Missed Same $numMissedSame\n";
print "Missed Diff $numMissedDiff\n";

print "Found JS $numFoundJS\n";
print "Found html $numFoundHTML\n";
print "Missed JS $numMissedJS\n";
print "Missed html $numMissedHTML\n";

close(OUT);


#normalized
my $nnumAds 		= $numAds / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff),1);
my $nnumJS  		=  $numJS / max($contentSize, ($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumInteractive 	= $numInteractive / max($numJS, $contentSize, 1);
my $nnumFoundSame 	= $numFoundSame / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumFoundDiff 	= $numFoundDiff / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumMissedSame 	= $numMissedSame / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumMissedDiff 	= $numMissedDiff / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $ninteractiveJSguys 	= $interactiveJSguys / max($contentSize, 1);
my $nnumFoundJS 	= $numFoundJS / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumFoundHTML 	= $numFoundHTML / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumMissedJS 	= $numMissedJS / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $nnumMissedHTML 	= $numMissedHTML / max(($numFoundSame + $numFoundDiff + $numMissedSame + $numMissedDiff), 1);
my $ninteractiveHTML 	= $interactiveHTML / max($contentSize, 1);
my $nnumDomMods 	= $numDomMods / max($contentSize, 1);
my $njsNav 		= $jsNav / max($contentSize, 1);
my $njsCookies 		= $jsCookies / max($contentSize, 1);


#boolean
my $bnumAds = min(1, $numAds);
my $bnumJS  = min(1, $numJS);
my $bnumInteractive = min(1, $numInteractive);
my $bnumFoundSame = min(1, $numFoundSame);
my $bnumFoundDiff = min(1, $numFoundDiff);
my $bnumMissedSame = min(1, $numMissedSame);
my $bnumMissedDiff = min(1, $numMissedDiff);
my $binteractiveJSguys = min(1, $interactiveJSguys);
my $bnumFoundJS = min(1, $numFoundJS);
my $bnumFoundHTML = min(1, $numFoundHTML);
my $bnumMissedJS = min(1, $numMissedJS);
my $bnumMissedHTML = min(1, $numMissedHTML);
my $binteractiveHTML = min(1, $interactiveHTML);
my $bnumDomMods = min(1, $numDomMods);
my $bjsNav = min(1, $jsNav);
my $bjsCookies = min(1, $jsCookies);

open(OUT, ">>$pref" . "domClassificationNormalized.csv");
#print "URIR, Deferred?, #Ads, #JS, #Interactive, #Ajax from JS, #Ajax from HTML, #Found Same, #Found Diff, #Missed Same, #Missed Diff\n";
print OUT "$nnumAds, $nnumJS, $nnumInteractive, $ninteractiveJSguys, $ninteractiveHTML, $nnumFoundSame, "
	. "$nnumFoundDiff, $nnumMissedSame, $nnumMissedDiff"
	## new guys
	. "$nnumDomMods, $njsNav, $njsCookies\n";
close(OUT);

open(OUT, ">>$pref" . "domClassificationBoolean.csv");
#print "URIR, Deferred?, #Ads, #JS, #Interactive, #Ajax from JS, #Ajax from HTML, #Found Same, #Found Diff, #Missed Same, #Missed Diff\n";
print OUT "$bnumAds, $bnumJS, $bnumInteractive, $binteractiveJSguys, $binteractiveHTML, $bnumFoundSame, "
	. "$bnumFoundDiff, $bnumMissedSame, $bnumMissedDiff"
	## new guys
	. "$bnumDomMods, $bjsNav, $bjsCookies\n";
close(OUT);



sub trim($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

sub max2 {
    my ($max, @vars) = @_;
    for (@vars) {
        $max = $_ if $_ > $max;
    }
    if($max eq "")
    {
	return 0;
    }
    return $max;
}

sub isHTML($)
{
	my $content = $_[0];
	my $embedded = $_[1];
	my $cssFiles = $_[2];
	my @cssArr = split(/\n/, $cssFiles);

	#print "isHTML: $embedded\n";

	my $thisURL = new URI::URL $embedded;
	
	if($embedded =~ m/^data:/i)
	{
		##must be an embedded image
		return 1;
	}

	my $domain = $thisURL->host;
	my $path = $thisURL->path;		##may need to switch this to epath

	if($content =~ m/$path/ig)
	{
		return 1;
	}

	##getting the style sheets
	#<link rel="stylesheet" type="text/css" href="mln.css"/>	

	for my $l (@cssFiles)
	{
		$l = trim($l);
		if($l =~ m/\.css/ig)
		{
			##curl for the style sheet and look for the file in it.
			my $curlcmd = "curl -s $l";
			my @cssStuff = `$curlcmd`;
			my $cssAll = join("\n", @cssStuff);
			
			if($cssAll =~ m/$embedded/ig)
			{
				return 1;
			}
		}
	}


	return 0;
}

sub isSame($)
{
	my $resource = $_[0];
	my $domain = $_[1];

 		if($resource =~ /^http:\/\//i)
                {
                        ##absolute URI
                        my $rUrl = new URI::URL $resource;
                        my $rHost = $rUrl->host;

                        #print "\nHOSTS! $rHost == $domain \n\n";

                        if($rHost =~ m/$domain/ig)
                        {
                                #print ("$resource is same as $uri\n");
                                #$numFoundSame++;
				return 1;
                        }
                        else
                        {
                                #print ("$resource is diff than $uri\n");
                                #$numFoundDiff++;
				return 0;
                        }
                }
                else
                {
                        #print ("$resource is relative to $uri\n");
                        ##relative URI
			#$numFoundSame++;
                        return 1;
                }
	return 0;
}

