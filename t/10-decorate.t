#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::DbC;

my @report;
my $dbc = Assert::Refute::DbC->new(
    on_fail => sub {
        push @report, shift;
    },
);

my @trace;

# returns sum and difference of args
sub foo {
    push @trace, [wantarray, @_];

    my ($x, $y) = @_;

    # scalar context return is the last in parentheses, i.e. a sum
    # abs() is a deliberately added bug!
    return ($x - $y, abs($x + $y));
};

# Self-test

is scalar foo(12, 7), 19, "sum in scalar context";
is_deeply [foo(12, 7)], [5, 19], "sum + diff in list context";
is_deeply \@trace, [['', 12, 7], [1, 12, 7]], "trace worked";

*newfoo = $dbc->decorate(
    code     => \&foo,
    precond  => sub {
        my $report = shift;

        $report->is( scalar @_, 2, "2 arguments only" );
        $report->ok( defined wantarray, "no void context" );
        $report->like( $_[0], qr/^-?\d+$/, "1st arg integer" );
        $report->like( $_[1], qr/^-?\d+$/, "2nd arg integer" );

        $CTX{0} = $_[0];
        $CTX{1} = $_[1];
    },
    postcond => sub {
        my $report = shift;

        note explain \@_;

        $report->is( scalar @_, (wantarray ? 2 : 1), "Return as requested" );

        $report->is( $_[-1], $CTX{0} + $CTX{1}, "Sum as expected" );
    },
);

# Void context
@trace=();
@report=();
newfoo(2, 2);

is_deeply \@trace, [[undef, 2, 2]], "Original sub was called";
is scalar @report, 2, "void context is ok no more";
# TODO is_deeply \%CTX, {}, "Context confined";

if (my $rep = shift @report) {
    ok !$rep->is_passing, "no pasaran (precond)";
    is $rep->get_count, 4, "4 checks performed";
} else {
    ok 0, "No report found (precond)";
};

if (my $rep = shift @report) {
    ok !$rep->is_passing, "no pasaran (postcond)";
    is $rep->get_count, 2, "2 checks performed";
} else {
    ok 0, "No report found (postcond)";
};

# TODO scalar context

# List context
@trace=();
@report=();
my @list = newfoo(2, 2);

is_deeply \@list, [0,4], "List as expected";
is_deeply \@trace, [[1, 2, 2]], "Original sub was called in list context";
is scalar @report, 0, "Everything fine so far";

diag "<report>\n".$_->get_tap."</report>"
    for @report;

# TODO bug detected

done_testing;
