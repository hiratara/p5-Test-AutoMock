package Test::LazyMock;
use 5.008001;
use strict;
use warnings;
use Scalar::Util qw(blessed refaddr weaken);

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my %params = @_;

    # considering overloaded dereference operators, use ref of hash-ref
    my $self_fields = {
        _lazymock_methods => {},  # method name => code-ref
        _lazymock_isa => {},  # class name => 1
        _lazymock_name => $params{name},
        _lazymock_parent => $params{parent},
        _lazymock_children => {},  # name => instance
        _lazymock_calls => [],
    };
    # avoid cyclic reference
    weaken($self_fields->{_lazymock_parent});

    my $self = bless \$self_fields => $class;

    # parse all method definitions
    while (my ($k, $v) = each %{$params{methods} // {}}) {
        $self->lazymock_add_method($k => $v);
    }

    if (my $isa = $params{isa}) {
        my @args = ref $isa eq 'ARRAY' ? @$isa : ($isa, );
        $self->lazymock_isa(@args);
    }

    $self;
}

sub isa {
    my $class_or_self = shift;
    my ($name) = @_;

    # don't look for _lazymock_isa if $self is a class name
    if (blessed $class_or_self) {
        my $self_fields = $class_or_self->_get_fields;
        return 1 if $self_fields->{_lazymock_isa}{$name};
    }

    $class_or_self->SUPER::isa(@_);
}

sub lazymock_add_method {
    my ($self, $name, $code_or_value) = @_;
    my $self_fields = $self->_get_fields;

    my ($method, $child_method) = split /->/, $name, 2;

    # check duplicates with pre-defined methods
    die "`$method` has already been defined as a method"
        if exists $self_fields->{_lazymock_methods}{$method};

    # handle nested method definitions
    if (defined $child_method) {
        my $child = $self->lazymock_child($method);
        $child->lazymock_add_method($child_method, $code_or_value);
        return;
    }

    # check duplicates with fields
    die "`$method` has already been defined as a field"
        if exists $self_fields->{_lazymock_children}{$method};

    my $code;
    if (ref $code_or_value // '' eq 'CODE') {
        $code = $code_or_value;
    } else {
        $code = sub { $code_or_value };
    }

    $self_fields->{_lazymock_methods}{$name} = $code;
}

sub lazymock_isa {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    my %isa;
    @isa{@_} = map { 1 } @_;

    $self_fields->{_lazymock_isa} = \%isa;
}

sub lazymock_calls {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    @{$self_fields->{_lazymock_calls}}
}

sub lazymock_child {
    my ($self, $name) = @_;
    my $self_fields = $self->_get_fields;

    return if exists $self_fields->{_lazymock_methods}{$name};

    $self_fields->{_lazymock_children}{$name} //= do {
        # create new child
        my $child_mock = ref($self)->new(
            name => $name,
            parent => $self,
        );

        $self_fields->{_lazymock_children}{$name} = $child_mock;

        $child_mock;
    };
}

sub lazymock_reset {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    $self_fields->{_lazymock_calls} = [];
    $_->lazymock_reset for values %{$self_fields->{_lazymock_children}};
}

sub DESTROY {}

sub _get_fields {
    my $self = shift;
    my $class = blessed $self or die '$self is not an object';
    $self->SUPER::isa(__PACKAGE__) or die '$self is not a sub class';

    bless $self, __PACKAGE__;  # disable operator overloads
    my $fields = eval { $$self };
    bless $self, $class;
    $@ and die $@;

    $fields;
}

sub _call_method {
    my ($self, $meth, $ref_params, $default_handler) = @_;
    my $self_fields = $self->_get_fields;

    # follow up the chain of mocks and record calls
    my %seen;
    my $cur_call = [$meth, $ref_params];
    my $cur_mock = $self;
    while (defined $cur_mock && ! $seen{refaddr($cur_mock)}++) {
        my $cur_mock_fields = $cur_mock->_get_fields;
        push @{$cur_mock_fields->{_lazymock_calls}}, $cur_call;

        $cur_call = [
            join('->', $cur_mock_fields->{_lazymock_name} // '', $cur_call->[0]),
            $cur_call->[1],
        ];
        $cur_mock = $cur_mock_fields->{_lazymock_parent};
    }

    # return value
    if (my $code = $self_fields->{_lazymock_methods}{$meth}) {
        $code->(@$ref_params);
    } elsif (defined $default_handler) {
        $self->$default_handler(@$ref_params);
    } else {
        $self->lazymock_child($meth);
    }
}

sub AUTOLOAD {
    my ($self, @params) = @_;
    (my $meth = our $AUTOLOAD) =~ s/.*:://;

    $self->_call_method($meth => \@params, undef);
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

