package Test::LimitDecimalPlaces;

use warnings;
use strict;
use Carp;
use Exporter;
use Test::Builder;

use vars qw/ $VERSION @EXPORT @ISA /;

BEGIN {
    $VERSION = '0.01';
    @ISA     = qw/ Exporter /;
    @EXPORT  = qw/ limit_ok limit_ok_by limit_not_ok limit_not_ok_by /;
}

my $TestBuilder           = Test::Builder->new;
my $default_num_of_digits = 7;

sub import {
    my $self  = shift;
    my $pack  = caller;
    my $found = grep /num_of_digits/, @_;

    if ($found) {
        my ( $key, $value ) = splice @_, 0, 2;

        if ( $value < 0 ) {
            croak 'Value of limit number of digits must be a number greater than or equal to zero.';
        }
        unless ( $key eq 'num_of_digits' ) {
            croak 'Test::LimitDecimalPlaces option must be specified first.';
        }
        $default_num_of_digits = $value;
    }

    $TestBuilder->exported_to($pack);
    $TestBuilder->plan(@_);
    $self->export_to_level( 1, $self, $_ ) for @EXPORT;
}

sub _construct_err_msg {
    my ( $x, $y, $num_of_digits ) = @_;

    return
        sprintf( "%.${num_of_digits}f", $x ) . ' and '
      . sprintf( "%.${num_of_digits}f", $y )
      . ' are not equal by limiting decimal places is ' . $num_of_digits;
}

sub _check {
    my ( $x, $y, $num_of_digits ) = @_;

    my $is_array = 0;

    croak 'Value of limit number of digits must be a number '
      . 'greater than or equal to zero.' if ( $num_of_digits < 0 );
    $num_of_digits = int($num_of_digits);

    my ($ok, $diag) = (1, '');

    if (ref $x eq 'ARRAY' || ref $y eq 'ARRAY') {
        $is_array = 1;
        unless (scalar(@$x) == scalar(@$y)) {
            $ok = 0;
            $diag = "Got length of an array is " . scalar(@$x) .
                    ", but expected length of an array is " . scalar(@$y);
            return ($ok, $diag);
        }
    }

    if ($is_array) {
        for my $i ( 0 .. $#$x ) {
            ($ok, $diag) = _check($x->[$i], $y->[$i], $num_of_digits);
            unless ($ok) {
                $diag .= ', number of element is ' . $i . ' in array';
                last;
            }
        }
    } else {
        $ok = (
            sprintf( "%.${num_of_digits}f", $x ) ==
              sprintf( "%.${num_of_digits}f", $y ) );
        $diag = _construct_err_msg( $x, $y, $num_of_digits ) unless ($ok);
    }

    return ( $ok, $diag );
}

sub _flip {
    my ( $state, $x, $y, $num_of_digits, $is_array ) = @_;

    $state = !$state;
    my $diag;
    unless ($state) {
        if ($is_array) {
            $diag = 'Both of arrays are the same.';
        } else {
            $diag = _construct_err_msg( $x, $y, $num_of_digits );
            $diag =~ s/ not//;
        }
    }

    return ( $state, $diag );
}

sub limit_ok_by($$$;$) {
    my ( $x, $y, $num_of_digits, $test_name ) = @_;

    my ( $ok, $diag ) = _check( $x, $y, $num_of_digits, $test_name );
    return $TestBuilder->ok( $ok, $test_name ) || $TestBuilder->diag($diag);
}

sub limit_ok($$;$) {
    my ( $x, $y, $test_name ) = @_;

    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        limit_ok_by( $x, $y, $default_num_of_digits, $test_name );
    }
}

sub limit_not_ok_by($$$;$) {
    my ( $x, $y, $num_of_digits, $test_name ) = @_;

    my $is_array = 0;
    $is_array = 1 if (ref $x eq 'ARRAY' || ref $y eq 'ARRAY' );

    my ( $ok, $diag ) = _check( $x, $y, $num_of_digits, $test_name );
    ( $ok, $diag ) = _flip( $ok, $x, $y, $num_of_digits, $is_array );
    return $TestBuilder->ok( $ok, $test_name ) || $TestBuilder->diag($diag);
}

sub limit_not_ok($$;$) {
    my ( $x, $y, $test_name ) = @_;

    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        limit_not_ok_by( $x, $y, $default_num_of_digits, $test_name );
    }
}

1;
__END__

=head1 NAME

Test::LimitDecimalPlaces - Compare numerical values by limiting number of decimal places


=head1 VERSION

This document describes Test::LimitDecimalPlaces version 0.01


=head1 SYNOPSIS

    use Test::LimitDecimalPlaces tests => 5; # Can specify the test plan.

    # Equality test by default number of decimal places
    limit_ok(1.2345678, 1.2345678, 'Test the same floating-point values.');

    # Inequality test by default number of decimal places
    limit_not_ok( 0.0000001, 0.0000002, 'Test different values' );

    # Equality test by specified number of decimal places
    limit_ok_by(0.00000001, 0.000000006, 8, 'Test similar value.') ."\n"; # number of decimal places is 8

    # Inequality test by specified number of decimal places
    limit_not_ok_by( 0.00000001, 0.00000002, 8, 'Test different values.' ); # number of decimal places is 8

    # Compare arrays
    my @x = ( 0, 1, 0.1, 0.0000001, 0.0000001 );
    my @y = ( 0, 1, 0.1, 0.0000001, 0.00000006 );
    limit_ok(\@x, \@y, 'Compare arrays.');

    # Set a different default number of decimal places
    use Test::LimitDecimalPlaces num_of_digits => 6, tests => 1;
    limit_ok(1.234567, 1.234566, 'Test the similar floating-point values.');

=head1 DESCRIPTION

If compare floating point numbers normally, we cannot get the correct result on some environment.
This module was made to solve this problem.

This module provides test functions that can compare numerical values by limiting number of decimal places.
These functions are using splintf() internally to limit number of decimal places.


=head1 USAGE

=over

=item use Test::LimitDecimalPlaces;

Use with no args, then number of decimal places to limit defaults 7.

=item use Test::LimitDecimalPlaces num_of_digits => 6;

Use with argument of 'num_of_digits', then default number of decimal places to limit is set specified number.

This parameter must be a number greater than or equal to zero.

=item With test plan

This module can specify test plan. Like so:

    use Test::LimitDecimalPlaces tests => 1;

And this module can specify own options with test plan. Like so:

    use Test::LimitDecimalPlaces num_of_digits => 6, tests => 1;

Test::LimitDecimalPlaces-specific option must come first.

=back


=head1 FUNCTIONS

=over

=item limit_ok

limit_ok($x, $y, 'Description of test');

limit_ok(\@x, \@y, 'Description of test');

This function compares and check equality between given values by limiting default number of decimal places.

=item limit_ok_by

limit_ok_by($x, $y, $num_of_digits, 'Description of test');

limit_ok_by(\@x, \@y, $num_of_digits, 'Description of test');

Action of this function is almost the same as limit_ok().

But this function uses specified number of decimal places ($num_of_digits in case of the above instance).

=item limit_not_ok

limit_not_ok($x, $y, 'Description of test');

limit_not_ok(\@x, \@y, 'Description of test');

This function compares and check inequality between given values by limiting default number of decimal places.

=item limit_not_ok_by

limit_not_ok_by($x, $y, $num_of_digits, 'Description of test');

limit_not_ok_by(\@x, \@y, $num_of_digits, 'Description of test');

Action of this function is almost the same as limit_not_ok().

But this function uses specified number of decimal places ($num_of_digits in case of the above instance).

=back


=head1 CONFIGURATION AND ENVIRONMENT

Test::LimitDecimalPlaces requires no configuration files or environment variables.


=head1 DEPENDENCIES

Test::Exception (version 0.31 or later)


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-limitdecimalplaces@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
