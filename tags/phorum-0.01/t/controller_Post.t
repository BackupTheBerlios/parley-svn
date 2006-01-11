
use Test::More tests => 3;
use_ok( Catalyst::Test, 'Phorum' );
use_ok('Phorum::Controller::Post');

ok( request('post')->is_success );

