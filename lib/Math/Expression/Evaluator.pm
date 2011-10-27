package Math::Expression::Evaluator;
use strict;
use warnings;
use Math::Expression::Evaluator::Parser;
use Math::Expression::Evaluator::Util qw(is_lvalue);
use Data::Dumper;
use POSIX qw(ceil floor);
use Carp;

use Math::Trig qw(atan asin acos tan);

our $VERSION = '0.3.3';

=encoding UTF-8

=head1 NAME

Math::Expression::Evaluator - parses, compiles and evaluates mathematic expressions

=head1 SYNOPSIS

    use Math::Expression::Evaluator;
    my $m = Math::Expression::Evaluator->new;

    print $m->parse("a = 12; a*3")->val(), "\n";
    # prints 36
    print $m->parse("2^(a/3)")->val(), "\n";
    # prints 16 (ie 2**4)
    print $m->parse("a / b")->val({ b => 6 }), "\n";
    # prints 2
    print $m->parse("log2(16)")->val(), "\n";
    # prints 4

    # if you care about speed
    my $func = $m->parse('2 + (4 * b)')->compiled;
    for (0 .. 100){
        print $func->({b => $_}), "\n";
    }


=head1 DESCRIPTION

Math::Expression::Evaluator is a parser, compiler and interpreter for 
mathematical expressions. It can handle normal arithmetics 
(includings powers wit C<^> or C<**>), builtin functions like sin() and variables.

Multiplication C<*>, division C</> and modulo C<%> have the same precedence,
and are evaluated left to right. The modulo operation follows the standard
perl semantics, that is is the arguments are castet to integer before
preforming the modulo operation.

Multiple exressions can be seperated by whitespaces or by semicolons ';'. 
In case of multiple expressions the value of the last expression is 
returned.

Variables can be assigned with a single '=' sign, their name has to start 
with a alphabetic character or underscore C<[a-zA-Z_]>, and may contain 
alphabetic characters, digits and underscores.

Values for variables can also be provided as a hash ref as a parameter
to val(). In case of collision the explicitly provided value is used:

   $m->parse("a = 2; a")->val({a => 1}); 

will return 1, not 2.

The following builtin functions are supported atm:

=over 4

=item *

trignometric functions: sin, cos, tan

=item *

inverse trigonomic functions: asin, acos, atan

=item *

Square root: sqrt

=item * 

exponentials: exp, sinh, cosh

=item *

logarithms: log, log2, log10

=item * 

constants: pi() (you need the parenthesis to distinguish it from the 
variable pi)

=item * 

rounding: ceil(), floor()

=item *

other: theta (theta(x) = 1 for x > 0, theta(x) = 0 for x < 0)

=back

=head1 METHODS

=over 2

=item new

generates a new MathExpr object. accepts an optional argument, a hash ref
that contains configurations. If this hash sets force_semicolon to true, 
expressions have to be separated by a semicolon ';'.

=item parse

Takes a string as argument, and generates an Abstract Syntax Tree(AST) that 
is stored internally.

Returns a reference to the object, so that method calls can be chained:

    print MathExpr->new->parse("1+2")->val;

Parse failures cause this method to die with a stack trace. 

You can call C<parse> on an existing Math::Expression::Evaluator object to
re-use it, in which case previously set variables and callbacks persist
between calls.

This (perhaps contrived) example explains this:

    my $m = Math::Expression::Evaluator->new('a = 3; a');
    $m->val();
    $m->parse('a + 5');
    print $m->val(), "\n"   # prints 8, because a = 3 was re-used

If that's not what you want, create a new object instead - the constructor is
rather cheap.

=item compiled

Returns an anonymous function that is a compiled version of the current
expression. It is much faster to execute than the other methods, but its error
messages aren't as informative (instead of complaining about a non-existing 
variable it dies with C<Use of uninitialized value in...>).

Note that variables are not persistent between calls to compiled functions
(and it wouldn't make sense anyway, because such a function corresponds always 
to exactly one expression, not many as a MEE object).

Variables that were stored at the time when C<compiled()> is called are
availble in the compiled function, though.

=item val 

Executes the AST generated by parse(), and returns the number that the 
expression is evaluated to. It accepts an optional hash reference that
contain values for variables:

    my $m = MathExpr->new;
    $m->parse("(x - 1) / (x + 1)");
    foreach (0 .. 10) {
        print $_, "\t", $m->val({x => $_}), "\n";
    }

=item optimize

Optimizes the internal AST, so that subsequent calls to C<val()> will be 
a bit faster. See C<Math::Expression::Evaluator::Optimizer> for performance
considerations and informations on the implemented optimizations.

But note that a call to C<optimize()> only pays off if you call C<val()> 
multiple times.

=item variables

C<variables()> returns a list of variables that are used in the expression.

=item set_var_callback

Allows you to set a callback which the Match::Expression::Evaluator object
calls when it can't find a variable. The name of the variable is passed in
as the first argument. If the callback function can't handle that variable
either, it should die, just like the default one does.

    my $m = Math::Expression::Evaluator->new();
    $m->parse('1 + a');
    my $callback = sub { ord($_[0]) };
    $m->set_var_callback($callback);
    print $m->val();    # calls $callback, which returns 97
                        # so $m->val() return 98

The callback will be called every time the variable is accessed, so if it
requires expensive calculations, you are encouraged to cache it either
yourself our automatically with L<Memoize>.

=item set_function

Allows to add a user-defined function, or to override a built-in function.

    my $m = Math::Expression::Evaluator->new();
    $m->set_function('abs', sub { abs($_[0]) });
    $m->parse('abs(10.6)');
    print $m->val();

If you first compile the expression to a perl closure and then call
C<<$m->set_function>> again, the compiled function stays unaffected, so

    $m->set_function('f', sub { 42 });
    my $compiled = $m->parse('f')->compiled;
    $m->set_function('f', sub { -23 });
    print $compiled->();

print out C<42>, not C<-23>.

=item ast_size

C<ast_size> returns an integer which gives a crude measure of the logical
size of the expression. Note that this value isn't guarantueed to be stable
across multiple versions of this module. It is mainly intended for testing.

=back

=head1 SPEED

MEE isn't as fast as perl, because it is built on top of perl.

If you execute an expression multiple times, it pays off to either optimize
it first, or (even better) compile it to a pure perl function.

                   Rate  no_optimize     optimize opt_compiled     compiled
    no_optimize  83.9/s           --         -44%         -82%         -83%
    optimize      150/s          78%           --         -68%         -69%
    opt_compiled  472/s         463%         215%           --          -4%
    compiled      490/s         485%         227%           4%           --

This shows the time for 200 evaluations of C<2+a+5+(3+4)> (with MEE 0.0.5). 
As you can see, the non-optimized version is painfully slow, optimization
nearly doubles the execution speed. The compiled and the 
optimized-and-then-compiled versions are both much faster.

With this example expression the optimization prior to compilation pays off
if you evaluate it more than 1000 times. But even if you call it C<10**5>
times the optimized and compiled version is only 3% faster than the directly
compiled one (mostly due to perl's overhead for method calls).

So to summarize you should compile your expresions, and if you have really
many iterations it might pay off to optimize it first (or to write your
program in C instead ;-).

=head1 BUGS AND LIMITATIONS

=over 4

=item *

Modulo operator produces an unnecessary big AST, making it relatively slow

=back

=head1 INTERNALS

The AST can be accessed as C<$obj->{ast}>. Its structure is described in 
L<Math::Expression::Evaluator::Parser> (or you can use L<Data::Dumper> 
to figure it out for yourself). Note that the exact form of the AST is
considered to be an implementation detail, and subject to change.

=head1 SEE ALSO

L<Math::Expression> also evaluates mathematical expressions, but also handles
string operations.

If you want to do symbolic (aka algebraic) transformations, L<Math::Symbolic> 
will fit your needs.

=head1 LICENSE

This module is free software. You may use, redistribute and modify it under
the same terms as perl itself.

=head1 COPYRIGHT

Copyright (C) 2007 - 2009 Moritz Lenz,
L<http://perlgeek.de/>, moritz@faui2k3.org

=head1 DEVELOPMENT

You can obtain the latest development version from github
L<http://github.com/moritz/math-expression-evaluator>.

    git clone git://github.com/moritz/math-expression-evaluator.git

If you want to contribute something to this module, please ask me for
a commit bit to the github repository, I'm giving them out freely.

=head1 KNOWN USERS

L<http://www.tlhiv.org/mpgraph/> uses Math::Expression::Evaluator.

If you know other projects that use this module, please inform the author.

=head1 ACKNOWLEDGEMENTS

The following people have contributed to this module, in no particular order:

=over

=item Leonardo Herrera

Initial patch for C<set_function>

=item Tina Müller

Helpful feedback

=item Troy Henderson

Bug report for a misparse, feedback

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{tokens}       = [];
    $self->{variables}    = {};
    $self->{var_callback} = sub { confess "Variable '$_[0]' not defined" };

    my $first = shift;

    if (defined $first){
        if (ref $first){
            $self->{config} = $first;
            $self->parse(shift) if @_;
        } else {
            $self->parse($first);
        }
    }

    return $self;
}


# parse a text into an AST, stores the AST in $self->{ast}
sub parse {
    my ($self, $text) = @_;
    $self->{ast} =
        Math::Expression::Evaluator::Parser::parse($text, $self->{config});
    return $self;
}



sub optimize {
    my ($self) = @_;
    require Math::Expression::Evaluator::Optimizer;
    $self->{ast} = Math::Expression::Evaluator::Optimizer::_optimize($self, $self->{ast});
    return $self;
}

# evaluates an arbitrary AST, and returns its value
sub _execute {
    my ($self, $ast) = @_;
    my %dispatch = (
            '/' => sub {1 / $_[0]->_execute($_[1])},
            '-' => sub {-$_[0]->_execute($_[1])},
            '+' => \&_exec_sum,
            '*' => \&_exec_mul,
            '%' => sub {$_[0]->_execute($_[1]) % $_[0]->_execute($_[2]) },
            '^' => sub {$_[0]->_execute($_[1]) **  $self->_execute($_[2])},
            '**' => sub {$_[0]->_execute($_[1]) **  $self->_execute($_[2])},
            '=' => \&_exec_assignment,
            '&' => \&_exec_function_call,
            '{' => \&_exec_block,
            '$' => sub { my $self = shift; $self->_variable_lookup(@_) },
    );
#   print STDERR "Executing " . Dumper($self->{ast});
    if (ref $ast ){
        my @a = @$ast;
        my $op = shift @a;
        if (my $fun = $dispatch{$op}){
            return &$fun($self, @a);
        } else {
            confess ("Operator '$op' not yet implemented\n");
        }
    } else {
        $ast;
    }
}

sub set_var_callback {
    $_[0]->{var_callback} = $_[1];
}

# executes a sum
sub _exec_sum {
    my $self = shift;
    # avoid addition for unary plus, for overloaded objects
    my $sum = $self->_execute(shift);
    foreach (@_){
        $sum = $sum + $self->_execute($_);
    }
    return $sum;
}

# executes a value
sub val {
    my $self = shift;
    $self->{temp_vars} = shift || {};
    my $res =  $self->_execute($self->{ast});
    $self->{temp_vars} = {};
    return +$res;
}

# executes a block, eg a list of statements
sub _exec_block {
    my $self = shift;
#   warn "Executing block: ". Dumper(\@_);
    my $res;
    foreach (@_){
        $res = $self->_execute($_);
    }
    $res;
}

# executes a multiplication 
sub _exec_mul {
    my $self = shift;
    my $prod = 1;
    foreach (@_){
        $prod *= $self->_execute($_);
    }
    $prod;
}

# executes an _assignment
sub _exec_assignment {
    my ($self, $lvalue, $rvalue) = @_;
    if (!is_lvalue($lvalue)){
        confess('Internal error: $lvalue is not a "variable" AST');
    }
    return $self->{variables}{$lvalue->[1]} = $self->_execute($rvalue);
}


my %builtin_dispatch_table = (
    'sqrt'  => sub { sqrt $_[0] },
    'ceil'  => sub { ceil $_[0] },
    'floor' => sub { floor $_[0]},
    'sin'   => sub { sin  $_[0] },
    'asin'  => sub { asin $_[0] },
    'cos'   => sub { cos  $_[0] },
    'acos'  => sub { acos $_[0] },
    'tan'   => sub { tan  $_[0] },
    'atan'  => sub { atan $_[0] },
    'exp'   => sub { exp  $_[0] },
    'log'   => sub { log  $_[0] },
    'sinh'  => sub { (exp($_[0]) - exp(-$_[0]))/2},
    'cosh'  => sub { (exp($_[0]) + exp(-$_[0]))/2},
    'log10' => sub { log($_[0]) / log(10) },
    'log2'  => sub { log($_[0]) / log(2) },
    'theta' => sub { $_[0] > 0 ? 1 : 0 },
    'pi'    => sub { 3.141592653589793 },
);


sub set_function {
    my ($self, $name, $func) = @_;

    $self->{_user_dispatch_table}->{$name} = $func;
}

# executes a function call
sub _exec_function_call {
    my $self = shift;
    my $name = shift;

    my %dispatch_table = %builtin_dispatch_table;

    my %user_fun = %{$self->{_user_dispatch_table} || {} };
    while (my ($k, $v) = each %user_fun) {
        $dispatch_table{$k} = $v;
    }

    if (my $fun = $dispatch_table{$name}){
        return $fun->(map {$self->_execute($_)} @_);
    } else {
        confess("Unknown function: $name");
    }
}

# checks if a variable is defined, and returns its value
sub _variable_lookup {
    my ($self, $var) = @_;
#    warn "Looking up <$var>\n";
    if (exists $self->{temp_vars}->{$var}){
        return $self->{temp_vars}->{$var};
    } elsif (exists $self->{variables}->{$var}){
        return $self->{variables}->{$var};
    } else {
        $self->{var_callback}->($var);
    }
}

# used for testing purposes only:
# returns the (recursive) number of operands in the AST
sub ast_size {
    my ($self, $ast) = @_;
    $ast = defined $ast ? $ast : $self->{ast};
    return 1 unless ref $ast;
    my $size = -1; # the initial op/type should be ignored
    for (@$ast){
        $size += $self->ast_size($_);
    }
    return $size;
}

sub variables {
    my ($self) = shift;
    my %vars;
    my $v;
    my @todo = ($self->{ast});
    while (@todo){
        my $ast = shift @todo;
        next unless ref $ast;
        if ($ast->[0] eq '$'){
            $vars{$ast->[1]}++;
        } else {
            # XXX do we need push the first element of @$ast?
            push @todo, @$ast;
        }
    }
    return sort keys %vars;
}

# emit perl code for an AST.
# needed for compiling an expression into a anonymous sub
sub _ast_to_perl {
    my ($self, $ast) = @_;;
    return $ast unless ref $ast;

    my $joined_operator = sub {
        my $op = shift;
        return sub {
            join $op, map { '(' . $self->_ast_to_perl($_).  ')' } @_
        };
    };

    my %translations = (
        '$'     => sub { qq/( exists \$vars{$_[0]} ? \$vars{$_[0]} : exists \$default_vars{$_[0]} ? \$default_vars{$_[0]} : \$self->{var_callback}->("$_[0]")) / },
        '{'     => sub { join "\n", map { $self->_ast_to_perl($_) . ";" } @_ },
        '='     => sub { qq/\$vars{$_[0][1]} = / . $self->_ast_to_perl($_[1]) },
        '+'     => &$joined_operator('+'),
        '*'     => &$joined_operator('*'),
        '^'     => &$joined_operator('**'),
        '%'     => &$joined_operator('%'),
        '-'     => sub {  '-(' . $self->_ast_to_perl($_[0]) . ')' },
        '/'     => sub { '1/(' . $self->_ast_to_perl($_[0]) . ')' },
        '&'     => sub { $self->_function_to_perl(@_) },
    );
    my ($action, @rest) = @$ast;
    my $do = $translations{$action};
    if ($do){
        return &$do(@rest);
    } else {
        confess "Internal error: don't know what to do with '$action'";
    }
}

{
    my %builtins = (
        sqrt    => sub {  "sqrt($_[0])" },
        ceil    => sub {  "ceil($_[0])" },
        floor   => sub { "floor($_[0])" },
        sin     => sub {   "sin($_[0])" },
        asin    => sub {  "asin($_[0])" },
        cos     => sub {   "cos($_[0])" },
        acos    => sub {  "acos($_[0])" },
        tan     => sub {   "tan($_[0])" },
        atan    => sub {  "atan($_[0])" },
        exp     => sub {   "exp($_[0])" },
        log     => sub {   "log($_[0])" },
        sinh    => sub { "do { my \$t=$_[0]; (exp(\$t) - exp(-(\$t)))/2}" },
        cosh    => sub { "do { my \$t=$_[0]; (exp(\$t) + exp(-(\$t)))/2}" },
        log10   => sub {   "log($_[0]) / log(10)" },
        log2    => sub {   "log($_[0]) / log(2)" },
        theta   => sub { "$_[0] > 0 ? 1 : 0" },
        pi      => sub { "3.141592653589793" },
    );

    sub _function_to_perl {
        my ($self, $name, @args) = @_;
        if ($self->{_user_dispatch_table}->{$name}) {
            return qq[\$user_functions{'$name'}->(]
                   . join(',', map { $self->_ast_to_perl($_) } @args)
                   . qq[)];
        }
        my $do = $builtins{$name};
        if ($do){
            return $do->(map { $self->_ast_to_perl($_) } @args );
        } else {
            confess "Unknow function '$name'";
        }
    }
}

sub compiled {
    my $self = shift;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse  = 1;

    # the eval will close over %user_functions
    # if it contains any calls to it. Closures FTW!
    my %user_functions = %{ $self->{_user_dispatch_table} || {} };

    my $text = <<'CODE';
sub {
    my %vars = %{; shift || {} };
    use warnings FATAL => qw(uninitialized);
    no warnings 'void';
    my %default_vars = %{; 
CODE
    chomp $text;
    $text .= Dumper($self->{variables}) . "};\n    ";
    $text .= $self->_ast_to_perl($self->{ast});
    $text .= "\n}\n";
#    print STDERR "\n$text";
    my $res =  eval $text;
    confess "Internal error while compiling: $@" if $@;
    return $res;
}

1;

# vim: sw=4 ts=4 expandtab
