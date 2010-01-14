use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 11 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub e {
    return $m->parse(shift)->val();
}

sub c {
    return &{$m->parse(shift)->compiled}();
}

$m->set_function('abs', sub { abs($_[0]) });
is e('abs(-10.6)'),     10.6, 'Can define user function (1)';
is c('abs(-10.6)'),     10.6, 'Can define user function (1, compiled)';

is e('abs(-2)'),        2, 'Can define user function (2)';
is c('abs(-2)'),        2, 'can define user function (2, compiled)';


$m->set_function('round', sub { int($_[0] + .5) });

is e('round(10.1)'),    10, 'round(10.1)';
is e('round(0.9)'),      1, 'round(0.9)';
is c('round(10.1)'),    10, 'round(10.1) - compiled';
is c('round(0.9)'),      1, 'round(0.9) - compiled';

# test overriding of existing functions

$m->set_function('sin', sub { 42 });
is e('sin(4)'), 42, 'can override built-in functions';
is c('sin(4)'), 42, 'can override built-in functions (compiled)';

# vim: sw=4 ts=4 expandtab syn=perl
