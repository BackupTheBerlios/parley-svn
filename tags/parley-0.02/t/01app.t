use Test::More tests => 2;
BEGIN { use_ok( Catalyst::Test, 'Parley' ); }

ok( request('/')->is_success );
