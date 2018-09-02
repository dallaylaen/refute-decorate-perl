package Assert::Refute::DbC;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.01';

=head1 NAME

Assert::Refute::DbC - add Assert::Refute-based contract to existing method

=head1 SYNOPSIS

Say we have a module C<Foo> with method C<do_thing>, and we want to ensure
certain invariants hold for this method, without altering C<Foo> source.

Here is how:

    use Foo;
    use Assert::Refute::DbC;
    use Assert::Refute::T::Basic;

    set_method_contract (
        module    => 'Foo',
        method    => 'do_thing',
        precond   => sub {
            ...
        },
        postcond  => sub {
            ...
        },
        on_fail   => sub {
            die $_[0]->get_tap;
        },
    );

=head1 EXPORT

A hash C<%CTX> are exported by default.
It may be used for communication between precondition and postcondition.

=head1 METHODS

=cut

use Moo;
use Carp;

use Assert::Refute::Report;
use parent 'Exporter';

our %CTX;
our @EXPORT = qw(%CTX);

has module => is => 'rw';
has on_fail => is => 'rw';

=head2 set_method_contract(%)

Adds contract blocks around given function.

Options may include:

=over

=item * module(*) - the module to work on

=item * method(*) - the method to work on

=item * on_fail(*) - what to do in case of failure

=item * precond  - BLOCK containing assertions about arguments.

=item * postcond - BLOCK containing assertions about returned values.

=back

The C<%CTX> hash is localized before calling the C<precond> callback,
and untouched until C<postcond> callback is called.
Use it to communicate data between the two.

=cut

sub set_method_contract {
    my ($self, %opt) = @_;

    my $target  = delete $opt{module}  || $self->module;
    my $name    = delete $opt{method};

    $opt{function} = $target->can($name);
    croak "Cannot find sub $name in package $target"
        unless $opt{function};

    my $newcode = $self->decorate( %opt );

    no strict 'refs';       ## no critic
    no warnings 'redefine'; ## no critic
    # TODO copy prototype
    *{ $target."::".$name } = $newcode;
};

=head2 decorate

Arm an existing function with contract and return generated code.

=cut

sub decorate {
    my ($self, %opt) = @_;

    my $on_fail = $opt{on_fail} || $self->on_fail;

    my $orig = $opt{function};
    croak "Argument 'function' must be a CODE reference and not ".(ref $orig || 'SCALAR')
        unless UNIVERSAL::isa( $orig, 'CODE');

    my $precond     = _sub_to_contract($opt{precond}, $on_fail);
    my $postcond    = _sub_to_contract($opt{postcond}, $on_fail);

    my $newcode = sub {
        local %CTX;

        # propagate list/scalar/void context onto precond and postcond
        if (wantarray) {
            my @unused = $precond->(@_);
            my @ret    = do {
                local %CTX;
                $orig->(@_);
            };
            @unused    = $postcond->(@ret);
            return @ret;
        } elsif( defined wantarray ) {
            my $unused = $precond->(@_);
            my $ret    = do {
                local %CTX;
                $orig->(@_);
            };
            $unused    = $postcond->($ret);
            return $ret;
        } else {
            $precond->(@_);
            do {
                local %CTX;
                $orig->(@_);
            };
            $postcond->();
            return;
        };

        die "Unreachable, file a bug in ".__PACKAGE__;
    };
};

sub _sub_to_contract {
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

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

This module should be merged into either Assert::Refute or Test::Deep.
Suggestions welcome.

Please report bugs via github or RT:

=over

=item * L<https://github.com/dallaylaen/refute-decorate-perl/issues>

=item * C<bug-assert-refute-t-deep at rt.cpan.org>

=item * L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Assert-Refute-DbC>

=back

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc Assert::Refute::DbC

You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Assert-Refute-DbC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Assert-Refute-DbC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Assert-Refute-DbC>

=item * Search CPAN

L<http://search.cpan.org/dist/Assert-Refute-DbC/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Assert::Refute::DbC

