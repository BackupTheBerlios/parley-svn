use Test::More tests => 2;
BEGIN { use_ok( Catalyst::Test, 'Forum' ); }

ok( request('/')->is_success );
