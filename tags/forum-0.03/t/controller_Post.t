
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Forum' );
use_ok('Forum::Controller::Post');

ok( request('post')->is_success );

