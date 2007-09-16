use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 29 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub e {
    return $m->parse(shift)->val();
}
sub o {
    return $m->parse(shift)->optimize->val();
}

my @tests = (
    ['1+2*3',      7,      '* over +'],
    ['1-2*3',      -5,     '* over -'],
    ['1+4/2',      3,      '/ over +'],
    ['1-4/2',      -1,     '/ over -'],
    ['3*2^4',      48,     '^ over *'],
    ['3-2^4',      -13,    '^ over -'],
    ['3+2^4',      19,     '^ over +'],
    ['16/2^3',     2,      '^ over /'],
    ['(1)',        1,      'Parenthesis 0'],
    ['(1+2)*3',    9,      'Parenthesis 1'],
    ['(1-2)*3',    -3,     'Parenthesis 2'],
    ['(1+2)^2',    9,      'Parenthesis 3'],
    ['(2)^(1+2)',  8,      'Parenthesis 4'],
    ['((1))',      1,      'Double Parenthesis'],
);

for (@tests){
    is e($_->[0]), $_->[1], $_->[2];
    is o($_->[0]), $_->[1], $_->[2] . ' (optimized)';
}

# vim: sw=4 ts=4 expandtab
