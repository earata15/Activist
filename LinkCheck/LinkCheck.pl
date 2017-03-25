#!/usr/bin/perl
# linkcheck.pl
#
# A Perl script that takes a list of URLs from an array and tests to see if the
# Search String exists at that location.
#
# If you are running Windows, I recomend installing Starberry Perl: http://strawberryperl.com/ 
# and wget from https://eternallybored.org/misc/wget/ 
# Here are search strings that indicate different things.

# This one holds the file name that populates our url array
$InputFile = "urllist.txt";

$OutputFile = "LinkCheckOutput.txt"

#This one is returned if the campaign is not found.
$SearchStringNotFound = "Campaign Not Found";

# This indicate the campaign is over.
$SearchStringOver = "modal-not-accepting show-initial";

# This is the name of a temporary file for the file wget gets.
$tempfile = "wgetGot-";


sub readUrlList
{
    # this line defines the inputfile's handle, opens the input file (<) by calling the file variable ($inputfile) and if it can't open the file it dies. The die command then allows you to populate a literal string. $! then populates any additional error perl has for why the file won't open.
	open LISTFILE, "< $InputFile" or die "cantopen$InputFile: $!";
	
    # Here we ask the chomp command to remove the newline charcter from each line in the file. This allow wget to process the links
    # We also set @URLlist to point at the input file's handle. The parenthesis set what will be targeted by chomp 
    		
    chomp(@URLlist = <LISTFILE>);
	#closes the file
    close LISTFILE; 
}
	# Alternative cmd to chomp: s/x/x/; --> s/[insert search string]/[insert what you'll substitute]/;" 
	# example: s/\n/spock/; will replace each newline chrachter with the string 'spock'
	# ('\n' = newline character)
	#acording to John's Dad there are a number of cool specific cmds to this substitute cmd that allow it to do more things

# This is a subroutine that processes each URL
sub processURL
{
    #we open the file we are going to write our results to and signify we are writing to is with the '>' sign
    open OUTFILE, "> $OutputFile" or die "cantopen$OutputFile: $!";
    
    # The parameter passed in to this function is the URL being tested.
    my $url = shift;

    # For debugging, we number all of the temp files
    my $urlfile = $tempfile . $urlCount . ".html";
    
    # This is the wget command we are going to run. For all the options that wget has, see:
    # https://linux.die.net/man/1/wget
    # I use -O to specify an output file name and -q to silence wget's chatty output.
    my $cmd = "wget -q -O $urlfile $url";
    
    # Print the command for debugging.
    # print "running $cmd\n";
    
    # We use the back tics to run the command.
    `$cmd`;
    
    # We check the exit status in built in variable $?
    if($?)
    {
        # We got some kind of error. Assume its 404.
        print OUTFILE"Dead Link: $url\n";
    }
    else
    {
        # Link is good. Open the file or stop the program if we can not.
        open URLFILE, "< $urlfile" or die "Could not open $urlfile: $!";
        # Assume not found
        $found = 0;
        # Go through the file one line at a time
        while(<URLFILE>)
        {
            # See if we can match the Not Found search string
            if(m/$SearchStringNotFound/)
            {
                print OUTFILE"Not Found: $url\n";
                # Remember that we matched something
                $found = 1;
                # Exit the while loop.
                last;
            }

            # See if we can match the Not Found search string
            if(m/$SearchStringOver/)
            {
                print OUTFILE"Over: $url\n";
                # Remember that we matched something
                $found = 1;
                # Exit the while loop.
                last;
            }z

            if($found)
            {
                # Exit the while loop.
                last;
            }
        }

        # If we found no match, must be active
        if(not $found)
        {
            print OUTFILE"Active: $url\n";
        }

        # Close the file or wget can't write to it next time.
        close URLFILE;
        
        #close the file we are writing to so you can open it outside the script
        close OUTFILE;
    }    

sub printResults
{
    # IF you want, you can collect stats in the above loop and
    # print them here.
    print "All Done.\n";
}


# Here is the "main" function that does all the work
sub main
{
	readUrlList();
    # This counts the number of urls.
    $urlCount = 0;
    # This loop processes all the URLs from the URLlist.
    foreach $url (@URLlist)
    {
        $urlCount += 1;
        processURL($url);
    }
    printResults();
}


# Call main
main();
