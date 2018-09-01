#!/usr/bin/env perl

use strict;
use warnings;

# This is a big and hard to modify class elsewhere in the project
BEGIN {
    package Foo;
    use Moo;
    has num => is => 'rw', default => sub { 0 };
    sub add {
        my ($self, $n) = @_;
        $self->{num} += $n;
    };
};

# Now we'd like to make sure certain conditions hold at runtime
#     without modifying the original code
use Assert::Refute::DbC qw(%CTX);
use Assert::Refute::T::Basic; # this imports ok, like & so on

my $refute = Assert::Refute::DbC->new(
    module => "Foo",
    on_fail => sub {
        # Or this could be one's favorite logging engine
        die $_[0]->get_tap;
    },
);

$refute->set_method_contract(
    method    => "add",
    precond   => sub {
        my ($report, $self, $arg, @rest) = @_;

        # save argument for future use
        # may use dclone() if needed
        $CTX{self} = $self;

        # equivalent to $report->is( ... )
        is scalar @rest, 0, "No extra args";
        like $arg, qr/^[-+]?\d+$/, "Argument is integer";
    },
    postcond  => sub {
        my ($report, $ret) = @_;

        # wantarray is preserved.
        return unless defined wantarray;

        # less stupid output condition wanted )
        is $ret, $CTX{self}->num, "Updated number returned";
    },
);

my $foo = Foo->new;

$foo->add(11); # ok
$foo->add(31); # ok

print $foo->num, "\n"; # 42

eval {
    $foo->add("life, universe, and everything"); # this dies
};

print $@; # A TAP report

