package Math::Expression::Evaluator::Util;

=head1 NAME

Math::Expression::Evaluator::Util - Common functions for 
Math::Expression::Evaluator

=head1 SYNPOSIS

    use Math::Expression::Evaluator::Util qw(simplify_ast is_lvalue);
    $ast = simplify_ast($ast);

    # ...
    if (is_lvalue($ast)){
        # $ast represents an lvalue, at the moment just a variable
    }

=head1 DESCRIPTION

This is package with common functions used in the different modules in 
the Math::Expression::Evaluator distribution.

=over

=item simplify_ast

C<simplify_ast> takes a reference to an AST, and returns a simplified 
version. It just prunes no-op AST nodes and flattens the AST.

For example it turns C<['*', [@foo]]> into C<[@foo]> for arbitrary values 
of C<@foo>.

For a description of the AST see L<Math::Expression::Evaluator::Parser>.

=item is_lvalue

C<is_lvalue($ast)> checks if (a simplified version of) C<$ast> represents 
something that can be assigned to, i.e. is a variable.

=back

=cut

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(simplify_ast is_lvalue);

sub simplify_ast {
    my $ast = shift;
    return $ast unless ref $ast;
    my @a = @$ast;
    my %simplifiable =  map { $_ => 1 } ('+', '*', '{');
    if (scalar @a == 2 && $simplifiable{$a[0]}){
        # turns ['+', $foo] into $foo
        return simplify_ast($a[1]);
    }
    my @res;
    for (@a){
        push @res, simplify_ast($_);
    }
    return \@res;
}

# checks if the given AST represents a lvalue of an _assignment
sub is_lvalue {
    my $ast = simplify_ast(shift);
    if (ref($ast) && $ast->[0] eq '$'){
        # simple variable name
        return 1;
    } else {
        return 0;
    }
}

1;
# vim: sw=4 ts=4 expandtab
