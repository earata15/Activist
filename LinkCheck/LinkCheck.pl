#!/usr/bin/perl
# snoopy.pl
#
# A Perl script that takes a list of URLs from an array and tests to see if the
# Search String exists at that location.
#
# If you are running Windows, I recomend installing Starberry Perl: http://strawberryperl.com/ 
# and wget from https://eternallybored.org/misc/wget/ 
# Here are search strings that indicate different things.

# This one holds the file name that populates our url array
$InputFile = "urllist.txt";

#This one is returned if the campaign is not found.
$SearchStringNotFound = "Campaign Not Found";

# This indicate the campaign is over.
$SearchStringOver = "modal-not-accepting show-initial";


# This line will be parsed to find out how much money the campaign has made out of their total goal
# It looks funny because it is a regular expression... regex's are used to identify strings that match a certain pattern
# We have to use a regex instead of an exact search string, because we don't know what the numbers are / they will be different for every URL
#$SearchStringFunded = "<strong>\$(\d*,?\d*,?\d*)<\/strong><span class=\"smaller\">
 #of \$(\d*,?\d*,?\d)(k?) goal<\/span>";
$SearchStringFunded = "<h2 class=\"goal\">";
$SearchStringFunded2 = "\$(\d*,?\d*,?\d*)";
$SearchStringFunded3 = "\$(\d*,?\d*,?\d*)(k?)";

# This is the name of a temporary file for the file wget gets.
$tempfile = "wgetGot-";



sub readUrlList
{
    # this line defines the inputfile's handle, opens the input file (<) by calling the file variable ($inputfile) and if it can't open the file it dies. The die command then allows you to populate a literal string. $! then populates any additional error the perl has for why the file won't open.
	open LISTFILE, "< $InputFile" or die "cantopen$inputfile: $!";
	
    # Here is the array of URLs in it.
	
	
    chomp(@URLlist = <LISTFILE>);
	#closes the file
    close LISTFILE; 
}
	# substitute cmd: s/x/x/; or s/insert search string/insert what you'll substitute/; 
	# example: s/\n//;
	# '\n' = newline character

# This is a subroutine that processes each URL
sub processURL
{
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
        print "Dead Link: $url\n";
    }
    else
    {
        # Link is good. Open the file or stop the program if we can not.
        open URLFILE, "< $urlfile" or die "Could not open $urlfile: $!";
        # Assume not found
        $found = 0;
        $goal = 0;
        $funded = 0;
        $totalNeeded = 0;
        # Go through the file one line at a time
        while(<URLFILE>)
        {
            # See if we can match the Not Found search string
            if(m/$SearchStringNotFound/)
            {
                print "Not Found: $url\n";
                # Remember that we matched something
                $found = 1;
                # Exit the while loop.
                last;
            }

            #this line contains the campaign's funding goal amount
            if($goal == 2){
                $goal = 3;
                if(m/$SearchStringFunded3/){
                    print "\$1 is: $1 \nand \$2 is: \n";
                    $totalNeeded = $1;
                    $totalNeeded +~ s/,//;

                    if(length($2)>0){
                        $totalNeeded = $totalNeeded * 1000;
                    }
                    if($funded>0 && $funded>=$totalNeeded){
                        print "Campaign Fully Funded\n";
                    }

                    print $funded . " raised out of " . $totalNeeded . " goal.\n"; 
                    } else{
                        print "uh oh, problem with goal=2 line. here's the html for this line: " . "\n";
                        print;
                        print "here's the regex that tried to match and failed: \n";
                        print $SearchStringFunded3 ."\n";
                }

            }

            # this line contains the amount of money already raised
            if($goal == 1){
                if(m/$SearchStringFunded2/){
                    print "\$1 is: $1\n";
                    $funded = $1;
                    $funded +~ s/,//;
                    print "funded is: $funded\n";

                }else{
                    print "uh oh, problem with goal=1 line. here's the html at this line: \n";
                    print;
                    print "here's the regex that tried to match and failed: \n";
                    print $SearchStringFunded2 . "\n";
                    
                }
                $goal = 2;
            }
            # the next two lines have information about the campaign's funding after this line is found
            if(m/$SearchStringFunded/){
                $goal = 1;
            }

            # See if we can match the Not Found search string
            if(m/$SearchStringOver/)
            {
                print "Over: $url\n";
                # Remember that we matched something
                $found = 1;
                # Exit the while loop.
                last;
            }

            if($found)
            {
                # Exit the while loop.
                last;
            }
        }

        # If we found no match, must be active
        if(not $found)
        {
            print "Active: $url\n";
        }

        # Close the file or wget can't write to it next time.
        close URLFILE;
    }    
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
