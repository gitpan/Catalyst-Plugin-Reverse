#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
use Test::More tests => 17;

is( get('/t00'), 'ok'   );
is( get('/t01'), '/t00' );
is( get('/t02'), ''     );
is( get('/t03'), 'http://localhost/t01' );
is( get('/t04'), 'http://localhost/t01' );
is( get('/t05'), 'URI::http' );
is( get('/t06'), '' );
is( get('/t07'), '/nonexistent' );
is( get('/t08'), '' );
is( get('/t09'), 'ok' );
is( get('/t10'), '/t01' );
is( get('/t11'), '/t01' );
like( get('/t12'), qr(Plugin::Reverse: can't found method 'nonexistent') );
is( get('/t13'), '/foo/bar/test' );
like( get('/t14'), qr(can't found method ) );
like( get('/t15'), qr(Plugin::Reverse: invalid name ) );
like( get('/t16'), qr(Plugin::Reverse: can't found controler ) );

