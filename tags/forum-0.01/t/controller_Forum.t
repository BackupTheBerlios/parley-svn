
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Forum' );
use_ok('Forum::Controller::Forum');

ok( request('forum')->is_success );

