use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 6 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub e {
    return $m->parse(shift)->val();
}

sub c {
    return &{$m->parse(shift)->compiled}();
}

$m->add_user_function('abs', sub { abs($_[0]) });
is e('abs(-10.6)'),     10.6;
is e('abs(-2)'),        2;
is e('abs(2)'),         2;

$m->add_user_function('round', sub { int($_[0] + .5) });

is e('round(10.1)'),    10;
is e('round(0.9)'),      1;

# vim: sw=4 ts=4 expandtab syn=perl
