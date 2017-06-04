#!/usr/bin/perl
# After OAuth.pl has been run and the token stored on disk, we can read from the google sheet of our choice
# I kept all original comments in this code, noted by an extra #

use Net::Google::Spreadsheets;
use Net::Google::DataAPI::Auth::OAuth2;
use Net::OAuth2::AccessToken;
use Storable;
use Spreadsheet::WriteExcel;


## Authentication code based on example from gist at 
##  https://gist.github.com/hexaddikt/6738247

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
my $service = Net::Google::Spreadsheets->new(
                         auth => $oauth2);


# access Prototype List spreadsheet and store in variable $spreadsheet
my $spreadsheet = $service->spreadsheet(
{
    title => 'Prototype List'
}
);

# I think you have to specify worksheet even if there is only one sheet
my $worksheet = $spreadsheet->worksheet(
{
    title => 'Sheet1'
}
);

# Here's where we can actually start doing stuff. 

# Create a new Excel workbook
my $workbook = Spreadsheet::WriteExcel->new('transfer.xls');
# Add a worksheet
my $excelsheet = $workbook->add_worksheet();

#loop through cells in google sheet and write to excel worksheet
my $i,$j;
for($i=1;$i<10;$i++){
    for($j=1;$j<60;$j++){
        my $cell = $worksheet->cell({col => $i, row => $j});
        my $content = $cell->content;
        $excelsheet->write($j, $i, $content);
    }
}
