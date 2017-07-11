#!/usr/bin/perl
# linkcheck.pl
#
# Master script that roughly combines the tasks of LinkCheck.pl and SheetCopy.pl. Scans google sheet and tests URLs, deleting ones
# that no longer meet our criteria. Creates local excel file (direct copy of original sheet) and output log in an Archives folder.
# ** Must have already created Google OAth Authentification token and have stored locally in the same folder as this file**
 

use Net::Google::Spreadsheets;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::OAuth2::AccessToken;
use Storable;
use Spreadsheet::WriteExcel;


# This one holds the file name that populates our url array
$InputFile = "urllist.txt";

#this is the name of the file that will receive the results of linkcheck, sans the file extension
$OutputFile = "LinkCheckOutput";

#this is the name of the output directory that we can call or create is it doesn't exist. Createing this directory does not happen if the name is called and the directory doesn't exist. We have to do that seperatley
$OutputDirectory = "archive/";
$TempFileDirectory = "temp/";


#This one is returned if the campaign is not found.
$SearchStringNotFound = "Campaign Not Found";

# This indicate the campaign is over.
$SearchStringOver = "modal-not-accepting show-initial";


# These regular expressions will be used to match the html lines that contain $$$ the campaign has made out of their total goal
# $SearchStringFunded matches the html line <h2 class="goal">, which precedes the two lines with the information we want
# $SearchStringFunded2 will match the line after that and capture the value in $1 -- total raised so far
# $SearchStringFunded3 will match the line after that and capture the value in $1 -- total $$ goal for campaign

$SearchStringFunded = "<h2 class=\"goal\">";
#$SearchStringFunded2 = "\$(\d*,?\d*,?\d*)";
$SearchStringFunded2 = "([0-9,]+)";
#$SearchStringFunded3 = "\$(\d*,?\d*,?\d*)(k?)";
$SearchStringFunded3 = "([0-9,kK]+)";

# used to match and find when the last donation was. We pull links that haven't received any donations in the past 2 months.
$SearchStringDonations = "supporter js-donation-content";
#$SearchStringDonations2 = "supporter-time"\>([\d\sa-z]+)";

# This is the name of a temporary file for the file wget gets, inside a folder called temp
$tempfile = "wgetGot-";

# This subroutine calls the function localtime. This function produces a variable representing the time down to the second. 
# We can use this variable to add to our filename for the output file, especially if we are creating an archive of output files.
sub CreateTimeStamp
{
# First we call the perl command localtime. Localtime populates a bunch of local variables that can only be called inside this one subroutine.
# use "my () = " to define local variables.
#     0    1    2     3     4    5     6     7     8
     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
# we have to add 1900 to the year variable
     $year += 1900;
#we have to add 1 to the month variable
     $mon += 1;
#here we define a new global variable called $TimeStamp. This variable has to be defined *after* localtime defines the local variables.
     $TimeStamp = "$year.$mon.$mday.$hour.$min.$sec";	

# instead of calling the variable $TimeStamp, if we want we cna also call the subroutine. It will return the value for the $TimeStamp varaible.
	 return $TimeStamp
	 }



sub getAuth
{
## Get the token that we saved previously in order to authenticate:
my $sessionfile = "stored_google_access.session";


## Be sure to edit the lines below to fill in your correct client 
## id and client secret!
my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
    client_id => '1044791211387-e6v00ng6a9mu75ut8q6bbr2ihjabephl.apps.googleusercontent.com',
    client_secret => 'csB6EF6hzvdMJcS_vUUVW0pt',
    scope => ['http://spreadsheets.google.com/feeds/'],
    redirect_uri => 'https://developers.google.com/oauthplayground',
                             );

## Deserialize the file so we can thaw the session and reuse the refresh token
my $session = retrieve($sessionfile);

my $restored_token = Net::OAuth2::AccessToken->session_thaw($session,
                                auto_refresh => 1,
                                profile => $oauth2->oauth2_webserver,
                                );

$oauth2->access_token($restored_token);
## Now we can use this token to access the spreadsheets 
## in our account:
$service = Net::Google::Spreadsheets->new(
                         auth => $oauth2);

}


# function for deleting information from row when URL is determined to be bad

sub deleteRow
{
    my $row = shift;
    my $i;
    for($i=1;$i<6;$i++){
          # get a cell
          my $cell = $worksheet->cell({col => $i, row => $row});

          # update input value of the cell to be nothing
          $cell->input_value('');
    }
}

sub processURL
{
    
    open OUTFILE, ">> $OutputDirectory$OutputFile$TimeStamp$Extension" or die "cantopen $OutPutDirectory$OutputFile$TimeStamp$Extension: $!";
    
    # The parameter passed in to this function is the URL being tested.
    my $url = shift; # change: add loop to go through column of URL's 

    # For debugging, we number all of the temp files
    my $urlfile = $TempFileDirectory . $tempfile . $urlCount . ".html";
    
    # This is the wget command we are going to run. For all the options that wget has, see:
    # https://linux.die.net/man/1/wget
    # I use -O to specify an output file name and -q to silence wget's chatty output.
    # Note: you will get some error messages from wget when LinkCheckMaster runs over empty rows, because it's trying to access a blank URL
    my $cmd = "wget -q -O $urlfile $url";
    
    # Print the command for debugging.
    # print "running $cmd\n";
    
    # We use the back tics to run the command.
    `$cmd`;
    
    # We check the exit status in built in variable $?
    if($?)
    {
        # We got some kind of error. Assume its 404.

        #delete row from Spreadsheet
        print OUTFILE "Dead Link: $url\n";
        #$deleteRow($urlCount);

    }
    else
    {
        # Link is good. Open the file or stop the program if we can not.
        open URLFILE, "< $urlfile" or die "Could not open $urlfile: $!";
        # Assume not found
        my $found = 0;
        my $goal = 0;
        my $lastDonation = 0;
        my $donationInfo = "";
        my $funded = 0;
        my $totalNeeded = 0;
        # Go through the file one line at a time
        while(<URLFILE>)
        {
            # See if we can match the Not Found search string
            if(m/$SearchStringNotFound/)
            {
                print OUTFILE "Not Found: $url\n";
                # Remember that we matched something
                $found = 1;
                # Exit the while loop.
                last;
            }

            #goal of this match is to capture the campaign's total funding goal
            #goal is an indicator variable that is set to 2 after the two other lines have already been matched,
            # and then changed so that this snippet of code only gets run once, for the correct line in the html doc
            if($goal == 2){
                $goal = 3;
                if(m/$SearchStringFunded3/){
                    #print "Matched: $&\n\$1 is: $1\n";
                    $totalNeeded = $1;
                    $totalNeeded =~ s/,//g;
                    $totalNeeded =~ s/[kK]/000/;
         
                    } else{
                        #this is all just for debugging
                        print "uh oh, problem with goal=2 line. here's the html for this line: " . "\n";
                        print;
                        print "here's the regex that tried to match and failed: \n";
                        print $SearchStringFunded3 ."\n";
                }

            }

            # goal of this match is to capture the amount of money already raised
            # goal is an indicator variable that was set to 1 after /$SearchStringFunded/ was matched the line before
            
            if($goal == 1){
                if(m/$SearchStringFunded2/){
                    $funded = $1;
                    $funded =~ s/,//g;

                }else{
                    #debugging help
                    print "uh oh, problem with goal=1 line. here's the html at this line: \n";
                    print;
                    print "here's the regex that tried to match and failed: \n";
                    print $SearchStringFunded2 . "\n";
                    
                }
                $goal = 2;
            }

            # the next two lines after this match have campaign's funding info; indicate by setting goal variable
            if(($goal==0)&&(m/$SearchStringFunded/)){
                #print "Matched first line: $&\n";
                $goal = 1;
            }

            # capture most recent donation time, in the form of "8 days ago", "2 months ago", etc, as displayed on page
            if(($lastDonation==1) && (m/supporter-time"\>([\d\sa-z]+)/)){
                $lastDonation = 2;
                my $donationTime = $1;
                $donationInfo = "Last donation was " . $donationTime . "\n";    
                my $good = 0;

                if($donationTime =~ m/day/){
                    $good = 1;
                }
                if($donationTime =~ m/min/){
                    $good = 1;
                }
                if($donationTime =~ m/hour/){
                    $good = 1;
                }
                if($donationTime =~ m/month/){
                    if($donationTime =~ m/([0-9]+)/){
                        if($1<3){
                            $good = 1;
                        }
                    }
                }

                if($good==1){
                    $donationInfo = $donationInfo . "Last donation was within past three months.\n\n";
                }else{
                    $donationInfo = $donationInfo . "Last donation was NOT within past three months, need to remove.\n\n";
                    deleteRow($urlCount);
                }
            }

            # once this line is reached we are in the donation section; set indicator variable lastDonation to 1
            if(($lastDonation==0) && (m/$SearchStringDonations/)){
                $lastDonation = 1;
            }

            # See if we can match the Not Found search string
            if(m/$SearchStringOver/)
            {
                print OUTFILE "Over: $url\n";
                # Remember that we matched something
                $found = 1;
                # Exit the while loop.
                last;
            }

            if($found)
            {
                # Exit the while loop & delete row on spreadsheet.
                deleteRow($urlCount);
                last;
            }
        }

        # If we found no match, must be active
        if(not $found)
        {
            print OUTFILE "Active: $url\n";
            if($funded>0 && $funded>=$totalNeeded){
                print OUTFILE "Campaign Fully Funded\n";
            }else{
                print OUTFILE "Campaign still needs funding. ";
                }

            print OUTFILE $funded . " raised out of " . $totalNeeded . " goal.\n";
            print OUTFILE $donationInfo;
        }

        # Close the file or wget can't write to it next time.
        close URLFILE;
        
        #close the file we are writing to so you can open it outside the script
        close OUTFILE;
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
	# this calls the createtimestamp subroutine and creates the timestamp variable
	CreateTimeStamp ();
	#mkdir creates a directory for our files to dump into
	mkdir $OutputDirectory;
    mkdir $TempFileDirectory;

	getAuth();
    # This counts the number of urls.
    $urlCount = 0;

    # access Prototype List spreadsheet and store in variable $spreadsheet
    $spreadsheet = $service->spreadsheet(
    {
        title => 'PrototypeCopy'
    }
    );

    # specify worksheet 
    $worksheet = $spreadsheet->worksheet(
    {
        title => 'Primary'
    }
    );
    # Create a new Excel workbook to write to
    my $workbook = Spreadsheet::WriteExcel->new($OutputDirectory . 'PrototypeArchive' . $TimeStamp . $Extension . '.xls');
    # Add a worksheet
    my $excelsheet = $workbook->add_worksheet();

    #declare local variables for use in following loop
    my $i, $j, $cell, $content;
    for($i=2;$i<75;$i++){
        for($j=1;$j<7;$j++){
            $cell = $worksheet->cell({col => $j, row => $i});
            $content = $cell->content;
            $excelsheet->write($i, $j, $content);
        }
        $urlCount = $i;
        $cell = $worksheet->cell({col => 4, row => $i});
        $content = $cell->content;
        processURL($content);
    }

    printResults();
	
}


# Call main
main();
