#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';
use Carp qw(confess);
use Benchmark qw(cmpthese);
use Math::Expression::Evaluator;
use Data::Dumper;

my $statement = '2 + a + 5 + (3+4)';

my $test = Math::Expression::Evaluator->new($statement);
print Dumper $test->{ast};
$test->optimize;
print Dumper $test->{ast};

sub with_optimize {
    my $count = shift || confess "foo";
    my $m = Math::Expression::Evaluator->new($statement);
    $m->optimize;
    for (1..$count){
        $m->val({a => $_});
    }
}

sub no_optimize {
    my $count = shift || confess "foo";
    my $m = Math::Expression::Evaluator->new($statement);
    for (1..$count){
        $m->val({a => $_});
    }
}

my %tests = (
        optimize       => sub { with_optimize(10) },
        no_optimize    => sub { no_optimize(10) },
);
#for (100,1000,10000){
#    print $_, "\n";
#    $tests{'opt ' . $_} = sub { with_optimize($_) };
#    $tests{'noopt ' . $_} = sub { no_optimize($_) };
#}

cmpthese(-2, \%tests);


# vim: expandtab
