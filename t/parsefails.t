use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 12 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub parse_fail {
	my ($string, $explanation) = @_;
	eval { $m->parse($string) };
	ok($@, $explanation);
}

parse_fail '1^',	'Dangling operator ^';
parse_fail '1*',	'Dangling operator *';
parse_fail '1/',	'Dangling operator /';
parse_fail '1+',	'Dangling operator +';
parse_fail '1-',	'Dangling operator -';
parse_fail '(1+2',	'unbalanced parenthesis 1';
parse_fail '1+2)',	'unbalanced parenthesis 2';
parse_fail '1 + - 2',	'successive operators 1';
parse_fail '1 ** 2',	'successive operators 1';

parse_fail '3 = 4',	'assignment to non-lvalue';

# force a semicolon between statements:
$m = Math::Expression::Evaluator->new({force_semicolon => 1});

parse_fail '2 3',	'space seperated expressions while force_semicolon';
