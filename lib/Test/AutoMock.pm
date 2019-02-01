package Test::AutoMock;
use 5.008001;
use strict;
use warnings;
use namespace::autoclean;
use Scalar::Util qw(blessed refaddr weaken);
use Test::More import => [qw(ok eq_array)];

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
        $self->automock_add_method($k => $v);
    }

    if (my $isa = $params{isa}) {
        my @args = ref $isa eq 'ARRAY' ? @$isa : ($isa, );
        $self->automock_isa(@args);
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

sub automock_add_method {
    my ($self, $name, $code_or_value) = @_;
    my $self_fields = $self->_get_fields;

    my ($method, $child_method) = split /->/, $name, 2;

    # check duplicates with pre-defined methods
    die "`$method` has already been defined as a method"
        if exists $self_fields->{_lazymock_methods}{$method};

    # handle nested method definitions
    if (defined $child_method) {
        my $child = $self->automock_child($method);
        $child->automock_add_method($child_method, $code_or_value);
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

sub automock_isa {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    my %isa;
    @isa{@_} = map { 1 } @_;

    $self_fields->{_lazymock_isa} = \%isa;
}

sub automock_calls {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    @{$self_fields->{_lazymock_calls}}
}

sub automock_child {
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

sub automock_reset {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    $self_fields->{_lazymock_calls} = [];
    $_->automock_reset for values %{$self_fields->{_lazymock_children}};
}

sub _find_call {
    my ($self, $method) = @_;
    my @calls = $self->automock_calls;
    grep { $_->[0] eq $method } @calls;
}

sub automock_called_with_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $method, $args) = @_;
    my @calls = $self->_find_call($method);
    my @calls_with_args = grep { eq_array $args, $_->[1] } @calls;
    ok scalar @calls_with_args,
       "$method has been called with correct arguments";
}

sub automock_called_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $method) = @_;
    ok !! $self->_find_call($method), "$method has been called";
}

sub automock_not_called_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $method) = @_;
    ok ! $self->_find_call($method), "$method has not been called";
}

sub DESTROY {}

sub _exec_without_overloads {
    my ($self, $code) = @_;
    my $class = blessed $self or die '$self is not an object';
    $self->SUPER::isa(__PACKAGE__) or die '$self is not a sub class';

    bless $self, __PACKAGE__;  # disable operator overloads
    my $ret = eval { $code->() };
    bless $self, $class;
    $@ and die $@;

    $ret;
}

sub _get_fields {
    my $self = shift;
    $self->_exec_without_overloads(sub { $$self });
}

sub _record_call {
    my ($self, $meth, $ref_params) = @_;

    # follow up the chain of mocks and record calls
    my %seen;
    my $cur_call = [$meth, $ref_params];
    my $cur_mock = $self;
    while (defined $cur_mock && ! $seen{refaddr($cur_mock)}++) {
        my $cur_mock_fields = $cur_mock->_get_fields;
        push @{$cur_mock_fields->{_lazymock_calls}}, $cur_call;

        my $method_name = $cur_call->[0];
        my $parent_name = $cur_mock_fields->{_lazymock_name};
        $method_name = "$parent_name->$method_name" if defined $parent_name;

        $cur_call = [$method_name, $cur_call->[1]];
        $cur_mock = $cur_mock_fields->{_lazymock_parent};
    }
}

sub _call_method {
    my ($self, $meth, $ref_params, $default_handler) = @_;
    my $self_fields = $self->_get_fields;

    $default_handler //= sub {
        my $self = shift;
        $self->automock_child($meth);
    };

    $self->_record_call($meth, $ref_params);

    # return value
    if (my $code = $self_fields->{_lazymock_methods}{$meth}) {
        $code->(@$ref_params);
    } else {
        $self->$default_handler(@$ref_params);
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

Test::AutoMock - It's new $module

=head1 SYNOPSIS

    use Test::AutoMock;

=head1 DESCRIPTION

Test::AutoMock is ...

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

