#!/usr/bin/perl

# rough sketch

# prompt User for a list of search terms;
# search GoFundMe using given search terms and produce an Excel document containing relevant info from search results:
# name of campaign, URL to campaign, location, funding goal, current funds

use Term::Prompt;

$urlfile = "";

sub searchUrl
{
    # grab HTML from search results page and create a list of URL's of pages for us to go through
    my $url = shift;

    my $cmd = "wget -q -O $urlfile $url";
    
    # Print the command for debugging.
    print "running $cmd\n\n";    
    # run the command.
    `$cmd`;

    if($?)
    {
        # We got some kind of error. Assume its 404.
	# probably change this at some point to write to a file instead of console
        print "Dead Link: $url\n";
    }
    else
    {
        # Link is good. Open the file or stop the program if we can not.
        open URLFILE, "< $urlfile" or die "Could not open $urlfile: $!";

        # to-do: search result info in the HTML, probably using HTML::TreeBuilder to parse the HTML into a tree
        # (HTML is saved in $urlfile)
        # looking for a div tag with class="js-fund-tile", and information nested within that tag
        # run URL against basic tests
        # if pass, pull information and format into an excel sheet - name of campaign, URL, location, funding goal

	}
}

sub main
{
	mkdir "temp/";
	print "\nEnter as many search terms as you like. \nType \"done\" when input is done.\n\n";
	# Here is where we get the code from the user:

	@searchTerms = ();
	$code = prompt('x', 'Search term: ', '', '');

	while($code !~ /^done$/){
		push(@searchTerms,$code);
		$code = prompt('x', 'Search term: ', '', '');
	} 

	my $count = 1;
	foreach $term (@searchTerms){
		$term =~ s/\s/\%/g;
		my $url = "https://www.gofundme.com/mvc.php?route=category&term=" . $term . "&country=US";
		my $url2 = $url . "&page=2";
		print "URL generated: $url\n";
		$urlfile = "temp/wgetGot-" . $count . ".html";
		searchUrl($url);
		searchUrl($url2);
		$count++;
	}
}

main();
