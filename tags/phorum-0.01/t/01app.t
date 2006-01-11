use Test::More tests => 2;
BEGIN { use_ok( Catalyst::Test, 'Phorum' ); }

ok( request('/')->is_success );
