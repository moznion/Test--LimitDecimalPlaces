use strict;
use warnings;
use utf8;

BEGIN {
    use Test::LimitDecimalPlaces tests => 2;
}

limit_ok(1.0, 1.0, 'Test same value.');
limit_ok(1.0000001, 1.00000006, 'Test similar value.') ."\n";
