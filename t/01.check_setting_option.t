use strict;
use warnings;
use utf8;

BEGIN {
    use Test::Most;
    use Test::LimitDecimalPlaces tests => 4;
}

lives_ok { Test::LimitDecimalPlaces->import() };
lives_ok { Test::LimitDecimalPlaces->import( num_of_digits => 5 ) };
dies_ok { Test::LimitDecimalPlaces->import( num_of_digits => -1 ) };
dies_ok { Test::LimitDecimalPlaces->import( _tests => 5, num_of_digits => 5 ) };

done_testing();
