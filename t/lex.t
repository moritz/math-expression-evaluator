use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 6 }

BEGIN {
    use_ok('Math::Expression::Evaluator::Lexer');
}

my $lex = \&Math::Expression::Evaluator::Lexer::lex;

eval {
    &$lex(undef, []);
};

ok $@, 'lex(undef, ...) -> error';

is scalar(@{&$lex('', [[Int => qr/\d+/]])}), 0, 'lex("", ...) returns []';

eval {
    &$lex('20', [['Int', qr/\d+/, sub { return }]]);
};

ok !$@, 'callbacks in lex() may return undef';

eval {
    &$lex('20', [['Int', qr/\d+/, sub { '' }]]);
};

ok !$@, 'callbacks in lex() may return empty string';

eval {
    &$lex('20', [['Int', qr/(?=\d+)/]]);
};

ok $@, 'A token may note have zero length';

# TODO: many more lexer tests
