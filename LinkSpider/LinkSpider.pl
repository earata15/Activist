#!/usr/bin/perl

# rough sketch

use Term::Prompt;
# this is first run skeleton that takes user input for search terms and creates an array
# to do : create URL's for search pages to visit, scrape HTML, curate a list of URL's of campaign pages


print "\nEnter as many search terms as you like. \nType \"done\" when input is done.\n\n";
# Here is where we get the code from the user:

@searchTerms = ();
$code = prompt('x', 'Search term: ', '', '');

while($code !~ /^done$/){
	push(@searchTerms,$code);
	$code = prompt('x', 'Search term: ', '', '');
} 

print "\nAn array has been formed with the following search terms: \n";
foreach $term (@searchTerms){
	# regex replace spaces in search term with % or whatever character that was
	#my $url = "www.gofundme.com" . "......." . $term;
	#searchUrl();
	print "\n" . $term;
}
print "\n";



sub searchUrl
{
	# grab HTML from search results page and create a list of URL's of pages for us to go through

	# pasted in wget command from Snoopy.pl / LinkCheck.pl... will change this to include our URL and otherwise suit our needs
    #my $cmd = "wget -q -O $urlfile $url";
    
    # Print the command for debugging.
    # print "running $cmd\n";
    
    # We use the back tics to run the command.
    #`$cmd`;

}
