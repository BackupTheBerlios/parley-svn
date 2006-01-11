
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Phorum' );
use_ok('Phorum::Controller::Forum');

ok( request('forum')->is_success );

