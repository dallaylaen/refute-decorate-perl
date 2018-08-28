package Assert::Refute::Decorate;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.0';

use Assert::Refute;
use parent 'Exporter';

our @EXPORT = qw(set_method_contract %CTX);
our %CTX;

sub set_method_contract(@) {
    my (%opt) = @_;

    my $target  = $opt{module};
    my $name    = $opt{method};
    my $on_fail = $opt{on_fail};

    my $orig = $target->can($name) or die "foobared";
    return $orig if $ENV{PERL_NDEBUG} // $ENV{NDEBUG};

    my $args   = sub_to_contract($opt{args}, $on_fail);
    my $void   = sub_to_contract($opt{return_void}, $on_fail); 
    my $scalar = sub_to_contract($opt{return_scalar}, $on_fail);
    my $array  = sub_to_contract($opt{return_array}, $on_fail); 

    my $newcode = sub {
        local %CTX;
        $args->(@_);

        if (wantarray) {
            my @ret = $orig->(@_);
            $array->($_[0], @ret);
            return @ret;
        } elsif( defined wantarray ) {
            my $ret = $orig->(@_);
            $scalar->($_[0], $ret);
            return $ret;
        } else {
            $orig->(@_);
            $void->($_[0]);
            return;
        };

        die "Unreachable";
    };

    no strict 'refs';
    no warnings 'redefine';
    *{ $target."::".$name } = $newcode;
};

sub sub_to_contract {
    my ($block, $callback) = @_;

    return sub {} unless $block and $callback;

    return sub {
        my $report = Assert::Refute::Report->new;
        $report->do_run($block, @_);
        if (!$report->is_passing) {
            $callback->($report, @_);
        };
    };
};


1;

