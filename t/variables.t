use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 10 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub e {
    return $m->parse(shift)->val();
}

sub c {
    return &{$m->parse(shift)->compiled}();
}

is e('a = 3'),      3,  'Assignment returns value';
is e('a'),          3,  'Variables persistent';
is e('a*a'),        9,  'Arithmetics with variables';

#reset old variable values
$m = Math::Expression::Evaluator->new();
is c('a = 3; a*a'), 9,  'Assignment returns value (compiled)';

$m->parse("a + b");
is $m->val({a => 1, b => 2}), 3, 'externally assigned variables';

$m->parse("a = 3; a");
is $m->val({a => 1}),   1,  'externally provided variables override internal ones';

# test that assignments in an expression don't modify the hash passed to
# the 'val' or the compiled function;

my $vars = { a => 1 };
$m->parse('a = 2');
$m->val($vars);
is $vars->{a},          '1',    'no side effects on externally provided variables';

&{$m->compiled}($vars);
is $vars->{a},          '1',    'no side effects on externally provided variables [compiled]';

$m->parse(' b = 5')->val;
is &{$m->parse('b')->compiled}, 5, 'compiled expressions can use prev. defined variables';


# vim: sw=4 ts=4 expandtab syn=perl
