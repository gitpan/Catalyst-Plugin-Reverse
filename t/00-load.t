#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Reverse' );
}

diag( "Testing Catalyst::Plugin::Reverse $Catalyst::Plugin::Reverse::VERSION, Perl $], $^X" );

