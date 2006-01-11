
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Forum' );
use_ok('Forum::Controller::User');

ok( request('user')->is_success );

