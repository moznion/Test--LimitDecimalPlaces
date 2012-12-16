use strict;
use warnings;
use utf8;

BEGIN {
    use Test::LimitDecimalPlaces num_of_digits => 6, tests => 2;
}

limit_ok(1.0, 1.0, 'Test same value.');
limit_ok(10.000001, 10.0000006, 'Test similar value.') ."\n";
