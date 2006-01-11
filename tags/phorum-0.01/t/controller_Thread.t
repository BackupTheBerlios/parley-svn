
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Phorum' );
use_ok('Phorum::Controller::Thread');

ok( request('thread')->is_success );

