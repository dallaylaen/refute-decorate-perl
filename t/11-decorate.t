#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    undef @ENV{qw{PERL_NDEBUG NDEBUG}};
};

BEGIN {
    package Foo;
    use Moo;
    has num => is => 'rw', default => sub { 0 };

    sub add {
        my ($self, $x) = @_;
        $self->{num} += $x;
    };
};

{
    package T; # don't pollute main as it has Test::More in it
    use Assert::Refute qw(:all);
    use Assert::Refute::Decorate;
    use Assert::Refute::T::Numeric;

    set_method_contract (
        module  => 'Foo',
        method  => 'add',
        on_fail => sub {
            die $_[0]->get_tap;
        },
        args    => sub {
            my ($contract, $obj, $arg, @rest) = @_;
            $CTX{old} = $obj->num;
            $CTX{delta} = $arg;
            is scalar @rest, 0, "No extra arguments";
            is_between $arg, -100, 100, "Small delta only";
        },
        return_scalar => sub {
            my ($contract, $obj, $ret) = @_;
            cmp_ok $ret, "==", $CTX{old} + $CTX{delta}, "Return as expected";
            is $ret, $obj->num, "Return reflected in obj";
            is_between $obj->num, -100, 100, "Small result only"
                or $obj->num($CTX{old});
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
