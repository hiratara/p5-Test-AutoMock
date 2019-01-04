package Test::LazyMock;
use 5.008001;
use strict;
use warnings;
use Scalar::Util qw(weaken);

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my %params = @_;

    bless {
        # TODO: support nested method defs
        _lazymock_methods => $params{methods},
        _lazymock_name => $params{name},
        _lazymock_parent => $params{parent},
        _lazymock_calls => [],
    } => $class;
}

sub lazymock_add_method {
    my ($self, $name, $code_or_value) = @_;

    my $code;
    if (ref $code_or_value // '' eq 'CODE') {
        $code = $code_or_value;
    } else {
        $code = sub { $code_or_value };
    }

    # TODO: support nested method defs
    $self->{_lazymock_methods}{$name} = $code;
}

sub lazymock_calls { @{$_[0]->{_lazymock_calls}} }

sub DESTROY {}

sub AUTOLOAD {
    my ($self, @params) = @_;
    (my $meth = our $AUTOLOAD) =~ s/.*:://;

    # follow up the chain of mocks and record calls
    my %seen;
    my $cur_call = [$meth, \@params];
    my $cur_mock = $self;
    while ($cur_mock && ! $seen{int($cur_mock)}++) {
        push @{$cur_mock->{_lazymock_calls}}, $cur_call;

        $cur_call = [
            join('->', $cur_mock->{_lazymock_name} // '', $cur_call->[0]),
            $cur_call->[1],
        ];
        $cur_mock = $cur_mock->{_lazymock_parent};
    }

    # return value
    my $code = $self->{_lazymock_methods}{$meth} //= do {
        weaken(my $weaken_self = $self);
        my $new_mock = ref($self)->new(
            name => $meth,
            parent => $weaken_self,
        );
        sub { $new_mock };
    };
    $code->(@params);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::LazyMock - It's new $module

=head1 SYNOPSIS

    use Test::LazyMock;

=head1 DESCRIPTION

Test::LazyMock is ...

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

