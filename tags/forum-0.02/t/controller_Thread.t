
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Forum' );
use_ok('Forum::Controller::Thread');

ok( request('thread')->is_success );

