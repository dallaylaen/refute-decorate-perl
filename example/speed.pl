#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark qw(cmpthese);
use Assert::Refute::DbC;
use Class::DbC;

BEGIN {
    package Foo;
    use Moo;
    has num => is => 'rw', default => sub { 0 };
    sub add {
        my ($self, $n) = @_;
        $self->{num} += $n;
    };

    package Foo::dbc;
    our @ISA = ("Foo");
    package Foo::refute;
    our @ISA = ("Foo");
};

{
    use namespace::local;
    use Assert::Refute::T::Basic;
    my $refute = Assert::Refute::DbC->new(
        module => "Foo::refute",
        on_fail => sub { die $_[0]->get_tap },
    );

    $refute->set_method_contract(
        method   => "add",
        precond  => sub {
            my ($report, $self, $arg, @rest) = @_;
            my $ctx = $report->context;
            $ctx->{self} = $self;
            is scalar @rest, 0, "No extra args";
            like $arg, qr/^[-+]?\d+$/, "Arg is integer";
        },
        postcond => sub {
            my ($report, $ret) = @_;
            my $ctx = $report->context;
            return unless defined $ctx->{wantarray};
            is $ret, $ctx->{self}->num, "Updated number returned";
        },
    );
};


$SIG{__DIE__} = \&Carp::confess;

{
    package Foo::DbC::Contract;

    Class::DbC->import(
        interface => {
            add => {
                precond => {
                    input_noextra => sub {
                        scalar @_ == 2;
                    },
                    input_numeric => sub {
                        $_[1] =~ /^[-+]?\d+$/;
                    },
                },
                postcond => {
                    return_equals => sub {
                        my ($self, $old, $results) = @_;
                        $self->num == $results->[0];
                    },
                },
            },
        },
        invariant => {
        },
    );

    __PACKAGE__->govern( "Foo::dbc" );
};

cmpthese( -1, {
    dbc => sub {
        my $x = Foo::dbc->new;
        $x->add(5) for 1..100;
    },
    refute => sub {
        my $x = Foo::refute->new;
        $x->add(5) for 1..100;
    },
});





