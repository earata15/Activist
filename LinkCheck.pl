#!/usr/bin/perl
# snoopy.pl
#
# A Perl script that takes a list of URLs from an array and tests to see if the
# Search String exists at that location.
#
# If you are running Windows, I recomend installing Starberry Perl: http://strawberryperl.com/ 
# and wget from https://eternallybored.org/misc/wget/ 
# Here are search strings that indicate different things.

#This one is returned if the campaign is not found.
$SearchStringNotFound = "Campaign Not Found";

# This indicate the campaign is over.
$SearchStringOver = "modal-not-accepting show-initial";

# This is the name of a temporary file for the file wget gets.
$tempfile = "wgetGot-";

# Here is the array of URLs in it. Using single quotes so that the special characters do not get processed.
@URLlist = (
    'https://www.gofundme.com/404',
    'https://www.gofundme.com/impeachpersky?ssid=884520528&pos=30',
    'https://www.gofundme.com/oregon-state-trooper-wounded-1225',
);

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
