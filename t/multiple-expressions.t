use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 7 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub o {
    return $m->parse(shift)->optimize->val();
}
sub e {
    return $m->parse(shift)->val();
}

my @tests = (
        ['1 2',          2, 'space delimited expressions'],
        ['1; 2',         2, 'colon delimited expressions'],
        ['(1+2) (3-8)', -5, 'space delimited expressions 2'],
        );

for (@tests){
    is e($_->[0]), $_->[1], $_->[2];
    is o($_->[0]), $_->[1], $_->[2] . ' (optimized)';
}

# vim: expandtab
