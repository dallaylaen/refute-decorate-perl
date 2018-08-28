#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    package Foo;
    use Moo;
    has num => is => 'rw', default => sub { 0 };

    sub add {
        my ($self, $x) = @_;
        $self->{num} += $x;
    };
};

use Assert::Refute::Decorate;

set_method_contract (
    module  => 'Foo',
    method  => 'add',
    on_fail => sub {
        die $_[0]->get_tap;
    },
    args    => sub {
        package T;
        use Assert::Refute qw(:all);
        use Assert::Refute::T::Numeric;
        my ($contract, $obj, $arg, @rest) = @_;
        is scalar @rest, 0, "No extra arguments";
        is_between $arg, -100, 100, "Small delta only";
    },
    return_scalar => sub {
        package T;
        my ($contract, $obj, $ret) = @_;
        is $ret, $obj->num, "Return as expected";
        is_between $ret, -100, 100, "Small result only";
    },
);

my $x = Foo->new;

lives_ok {
    scalar $x->add(50);
};

lives_ok {
    scalar $x->add(30);
};

is $x->num, 80, "num as expected";

throws_ok {
    scalar $x->add(100500);
} qr/not ok.*Small delta/;

is $x->num, 80, "num not changed";

throws_ok {
    scalar $x->add(30);
} qr/not ok.*Small result/;

is $x->num, 110, "num as expected";

done_testing;
