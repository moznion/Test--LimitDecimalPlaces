use strict;
use warnings;
use utf8;

BEGIN {
    use Test::LimitDecimalPlaces tests => 4;
}

limit_by(1.0, 1.0, 5, 'Test same value.');
limit_by(1.0, 1.0, 6, 'Test same value by different limit value.');
limit_by(1.00001, 1.000006, 5, 'Test similar value.');
limit_by(1.000001, 1.0000006, 6, 'Test similar value by different limit value.');
