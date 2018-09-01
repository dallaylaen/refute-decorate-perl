#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

# Reset variables that affect refute
BEGIN {
    undef @ENV{qw{PERL_NDEBUG NDEBUG}};
};

# The module to work on. This one is as stupid as possible.
BEGIN {
    package Foo;
    use Moo;
    has num => is => 'rw', default => sub { 0 };

    sub add {
        my ($self, $x) = @_;
        $self->{num} += $x;
    };
};

# Let's add contract on top
{
    package T; # don't pollute main as it has Test::More in it
    use Assert::Refute qw(:all);
    use Assert::Refute::DbC;
    use Assert::Refute::T::Numeric;

    my $decorator = Assert::Refute::DbC->new(
        on_fail => sub {
            die $_[0]->get_tap;
        },
    );
    $decorator->set_method_contract (
        module  => 'Foo',
        method  => 'add',
        in      => sub {
            my ($contract, $obj, $arg, @rest) = @_;
            $CTX{self}  = $obj;
            $CTX{delta} = $arg;
            $CTX{sum}   = $obj->num + $arg;
            is scalar @rest, 0, "No extra arguments";
            is_between $arg, -100, 100, "Small delta only";
            is_between $CTX{sum}, -100, 100, "Small result only";
        },
        out     => sub {
            my ($contract, $ret) = @_;
            my $obj = $CTX{self};
            cmp_ok $ret, "==", $CTX{sum}, "Return as expected";
            is $ret, $obj->num, "Return reflected in obj";
        },
    );
};

# main
my $x = Foo->new;

lives_ok {
    scalar $x->add(50);
} "Add lives";

lives_ok {
    scalar $x->add(30);
} "Add lives (2)";

is $x->num, 80, "num as expected";

throws_ok {
    scalar $x->add(100500);
} qr/not ok.*Small delta/;

is $x->num, 80, "num not changed";

throws_ok {
    scalar $x->add(30);
} qr/not ok.*Small result/;

is $x->num, 80, "num reset to original";

done_testing;
