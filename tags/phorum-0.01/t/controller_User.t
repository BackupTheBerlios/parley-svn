
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Phorum' );
use_ok('Phorum::Controller::User');

ok( request('user')->is_success );

