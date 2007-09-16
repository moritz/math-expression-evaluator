package Math::Expression::Evaluator::Optimizer;
use strict;
use warnings;

=head1 NAME

Math::Expression::Evaluator::Optimizer - Optimize M::E::E ASTs

=head1 SYNOPSIS

    use Math::Expression::Evaluator;
    my $m = Math::Expression::Evaluator->new("2 + 4*f");
    $m->optimize();
    for (0..100){
        print $m->val({f => $_}), "\n";
    }

=head1 DESCRIPTION

Math::Expression::Evaluator::Optimizer performs simple optimizations on the
abstract syntax tree from Math::Expression::Evaluator.

You should not use this module directly, but interface it via 
L<Math::Expression::Evaluator>.

The following optimizations are implemented:

=over

=item *

Constant sub expressions: C<variable + 3 * 4> is simplfied to 
C<variable + 12>.

=item *

Joining of constants in mixed constant/variable expressions: C<2 + var + 3>
is simplified to C<var + 5>. Works only with sums and products (but internally 
a C<2 - 3 + x> is represented as C<2 + (-3) + x>, so it actually works with 
differences and divisions as well).

=cut

my %is_commutative = (
            '+' => 1,
            '*' => 1,
        );

sub _optimize {
    my ($expr, $ast) = @_;
    if (ref $ast){
        my @nodes = @$ast;
        my $type = shift @nodes;
        if ($type eq '=' || $type eq '$'){
            # XXX what to do about assignments? more thoughts needed
            return $ast;
        }
        my @new_nodes = ($type);
        my $tainted = 0;
        for my $n (@nodes){
            push @new_nodes, _optimize($expr, $n);
            if (ref $new_nodes[-1]){
                $tainted = 1;
            }
        }
        if ($tainted){
            # try to optimize things like '2 + a +3' into 'a + 5'
            # is only allowed for commutative ops
            if ($is_commutative{$type}){
#                print STDERR "Trying commutative optimization\n";
                my @untainted = ($type);
                my @tainted = ($type);
                for (1..$#new_nodes) {
                    if (ref $new_nodes[$_]){
                        push @tainted, $new_nodes[$_];
                    } else {
                        push @untainted, $new_nodes[$_];
                    }
                }

                if (@untainted > 2) {
                    # there is something to optimize
                    push @tainted, $expr->_execute(\@untainted);
                    return \@tainted;
                } else {
                    # 'twas all in vain
                    return \@new_nodes;
                }
            } else {
                return \@new_nodes;
            }
        } else {
            return $expr->_execute(\@new_nodes);
        }
    } else {
        return $ast;
    }
}

1;

# vim: sw=4 ts=4 expandtab
