#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 2;

# load the persion module
use_ok('Parley::Version');

# make sure that we don't have a totally stupid version number
ok($Parley::VERSION >= 0.59, q{Version number isn't stupidly low});
