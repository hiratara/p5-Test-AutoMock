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

Test::AutoMock - A mock that can be used with a minimum setup

=head1 SYNOPSIS

    use Test::AutoMock;
    use Test::More;

    # a black box function you want to test
    sub get_metacpan {
        my $ua = shift;
        my $response = $ua->get('https://metacpan.org/');
        if ($response->is_success) {
            return $response->decoded_content;  # or whatever
        }
        else {
            die $response->status_line;
        }
    }

    # build and set up the mock
    my $mock_ua = Test::AutoMock->new(
        methods => {
            # implement only the method you are interested in
            'get->decoded_content' => "Hello, metacpan!\n",
        },
    );

    # action first
    my $body = get_metacpan($mock_ua);

    # then, assertion
    is $body, "Hello, metacpan!\n";
    $mock_ua->automock_called_with_ok('get->is_success' => []);
    $mock_ua->automock_not_called_ok('get->status_line');

    # print all recorded calls
    for ($mock_ua->automock_calls) {
        my ($method, $args) = @$_;
        note "$method(" . join(', ', @$args) . ")";
    }

=head1 DESCRIPTION

Test::AutoMock is a mock module designed to be used with a minimal setup.
AutoMock can respond to any method call and returns a new AutoMock instance
as a return value. Therefore, you can use it as a mock object without having
to define all the methods. Even if method calls are nested, there is no
problem.

Auto records all method calls on all descendants. You can verify the method
calls and its arguments after using the mock. This is not the "record and
replay" model but the "action and assertion" model.

You can also mock many overloaded operators and hashes, arrays with
L<Test::AutoMock::Overloaded>. If you want to apply monkey patch to use
AutoMock, check L<Test::AutoMock::Patch>.

Test::AutoMock is inspired by Python3's unittest.mock module.

=head1 ALPHA WARNING

This module is under development. The API, including names of classes and
methods, may be subject to BACKWARD INCOMPATIBLE CHANGES.

=head1 METHODS

=head2 new

    my $mock = Test::AutoMock->new(
        methods => {
            agent => 'libwww-perl/AutoMock',
            'get->is_success' => sub { 1 },
        },
        isa => 'LWP::UserAgent',
    );

Constructor of AutoMock. It takes the following parameters.

=over 4

=item methods

A hash-ref of method definitions. See L<automock_add_method>.

=item isa

A super class of this mock. See L<automock_isa>.
To specify multiple classes, use array-ref.

=back

=head2 automock_add_method

    $mock->automock_add_method(add_one => sub { $_[0] + 1 });
    $mock->automock_add_method('path->to->some_obj->name' => 'some_obj');

Define the behavior of AutoMock when calling a method.

The first argument is the method name. You can also specify nested names with
C<< -> >>. A call in the middle of a method chain is regarded as a field and
can not be defined as a method at the same time. For example, if you try to
specify C<< 'get_object->name' >> and C<'get_object'> as the same mock,
you'll get an error.

The second argument specifies the return value when the method is called.
If you specify a code reference, that code will be called on method invocation.
Be aware that C<$self> is not included in the argument.

=head2 automock_isa

    $mock->automock_isa('Foo', 'Hoge');

Specify the superclass of the mock. This specification only affects the C<isa>
method. It is convenient when argument is checked like L<Moose> field.

=head2 automock_child

    # return the $mock->some_field
    $mock->automock_child('some_field');

Return the mock's child. Since this call is not recorded, it is convenient when
you want to avoid recording unnecessary calls when writing assertions.

TODO: Support C<< -> >> notations.

=head2 automock_calls

    my @calls = $mock->automock_calls;

Returns all recorded method calls. The element of "calls" is a two-element
array-ref. The first element is a method name, and the second element is an
array-ref representing arguments.

Method calls to children are also recorded in C<$mock>. For example, calling
C<< $mock->child->do_it >> will record two calls C<'child'> and
C<< 'child->do_it' >>.

=head2 automock_reset

Erase all recorded method calls. Delete all method call history from descendant
mocks as well. It is used when you want to reuse mock.

=head2 automock_called_ok

    $mock->automock_called_ok('hoge->bar');

Checks if the method was called. It is supposed to be used with L<Test::More> .

=head2 automock_called_with_ok

    $mock->automock_called_with_ok(
        'hoge->bar', [10, 20],
    );

Checks if the method was called with specified arguments.

=head2 automock_not_called_ok

    $mock->automock_not_called_ok('hoge->bar');

Checks if the method was not called.

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

