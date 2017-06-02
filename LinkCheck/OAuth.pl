#!/usr/bin/perl

# Found this code, almost verbatim, at: https://stackoverflow.com/questions/30735920/authenticating-in-a-google-sheets-application
# Almost all comments are from the original poster

# Code to get a web-based token that can be stored 
# and used later to authorize our spreadsheet access. 
# This only needs to be run once, to get the initial token. Follow in-shell commands.

# Based on code from https://gist.github.com/hexaddikt/6738162

#-------------------------------------------------------------------

# To use this code:

# 1. Edit the lines below to put in your own
#    client_id and client_secret from Google. 
# 2. Run this script and follow the directions on 
#    the screen, which will give step you 
#    through the following steps:
# 3. Copy the URL printed out, and paste 
#    the URL in a browser to load the page. 
# 4. On the resulting page, click OK (possibly
#    after being asked to log in to your Google 
#    account). 
# 5. You will be redirected to a page that provides 
#    a code that you should copy and paste back into the 
#    terminal window, so this script can exchange it for
#    an access token from Google, and store the token.  
#    That will be the the token the other spreadsheet access
#    code can use. 


use Net::Google::DataAPI::Auth::OAuth2;
use Net::Google::Spreadsheets;
use Storable; #to save and restore token for future use
use Term::Prompt;


# Provide the filename in which we will store the access 
# token.  This file will also need to be readable by the 
# other script that accesses the spreadsheet and parses
# the contents. 

my $session_filename = "stored_google_access.session";


# Code for accessing your Google account.  The required client_id
# and client_secret can be found in your Google Developer's console 
# page, as described in the detailed instruction document.  This 
# block of code will also need to appear in the other script that
# accesses the spreadsheet. 

# Be sure to edit the lines below to fill in your correct client 
# id and client secret!

# (Emma's note: I already did this, but if you have problems John it might mean you need to make your own credentials)
my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
    client_id => '1044791211387-e6v00ng6a9mu75ut8q6bbr2ihjabephl.apps.googleusercontent.com',
    client_secret => 'csB6EF6hzvdMJcS_vUUVW0pt',
    scope => ['http://spreadsheets.google.com/feeds/'],
    redirect_uri => 'https://developers.google.com/oauthplayground',
                             );
# We need to set these parameters this way in order to ensure 
# that we get not only an access token, but also a refresh token
# that can be used to update it as needed. 
my $url = $oauth2->authorize_url(access_type => 'offline',
                 approval_prompt => 'auto');

# Give the user instructions on what to do:
print <<END

The following URL can be used to obtain an access token from
Google.  

1. Copy the URL and paste it into a browser.  

2.  You may be asked to log into your Google account if you 
were not logged in already in that browser.  If so, go 
ahead and log in to whatever account you want to have 
access to the Google doc. 

3. On the next page, click "Accept" when asked to grant access. 

4.  You will then be redirected to a page with a box in the 
left-hand column labeled  "Authorization code".  
Copy the code in that box and come back here. 

Here is the URL to paste in your browser to get the code:

$url

END
    ;

# Here is where we get the code from the user:
my $code = prompt('x', 'Paste the code obtained at the above URL here: ', '', ''); 

# Exchange the code for an access token:
my $token = $oauth2->get_access_token($code) or die;

# If we get to here, it worked!  Report success: 
print "\nToken obtained successfully!\n";
print "Here are the token contents (just FYI):\n\n";
print $token->to_string, "\n";

# Save the token for future use:
my $session = $token->session_freeze;
store($session, $session_filename);

print <<END2

Token successfully stored in file $session_filename.

Use that filename in your spreadsheet-access script to 
load the token as needed for access to the spreadsheet data. 

END2
;