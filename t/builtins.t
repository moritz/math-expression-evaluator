use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 9 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

my $epsilon = 1e-6;

sub e {
	return $m->parse(shift)->val();
}

sub is_approx {
	my ($expr, $expected, $message) = @_;
	ok abs($m->parse($expr)->val() - $expected) <= $epsilon, $message;
}

is e('sqrt(4)'),	2,		'sqrt';
is_approx 'pi()',	3.141592, 	'pi';
is_approx 'sin(pi())',	0,		'sin(pi())';
is_approx 'sin(pi()/2)', 1,		'sin(pi()/2)';
is_approx 'sin(0)',	0,		'sin(0)';
is_approx 'cos(0)',	1,		'cos(0)';
is_approx 'exp(0)',	1,		'exp(0)';
is_approx 'log2(8)',	3,		'log2(8)';
