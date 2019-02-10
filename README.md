# NAME

Test::AutoMock - A mock that can be used with a minimum setup

# SYNOPSIS

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

# DESCRIPTION

Test::AutoMock is a mock module designed to be used with a minimal setup.
AutoMock can respond to any method call and returns a new AutoMock instance
as a return value. Therefore, you can use it as a mock object without having
to define all the methods. Even if method calls are nested, there is no
problem.

Auto records all method calls on all descendants. You can verify the method
calls and its arguments after using the mock. This is not the "record and
replay" model but the "action and assertion" model.

You can also mock many overloaded operators and hashes, arrays with
[Test::AutoMock::Overloaded](https://metacpan.org/pod/Test::AutoMock::Overloaded). If you want to apply monkey patch to use
AutoMock, check [Test::AutoMock::Patch](https://metacpan.org/pod/Test::AutoMock::Patch).

Test::AutoMock is inspired by Python3's unittest.mock module.

# ALPHA WARNING

This module is under development. The API, including names of classes and
methods, may be subject to BACKWARD INCOMPATIBLE CHANGES.

# METHODS

## new

    my $mock = Test::AutoMock->new(
        methods => {
            agent => 'libwww-perl/AutoMock',
            'get->is_success' => sub { 1 },
        },
        isa => 'LWP::UserAgent',
    );

Constructor of AutoMock. It takes the following parameters.

- methods

    A hash-ref of method definitions. See [automock\_add\_method](https://metacpan.org/pod/automock_add_method).

- isa

    A super class of this mock. See [automock\_isa](https://metacpan.org/pod/automock_isa).
    To specify multiple classes, use array-ref.

## automock\_add\_method

    $mock->automock_add_method(add_one => sub { $_[0] + 1 });
    $mock->automock_add_method('path->to->some_obj->name' => 'some_obj');

Define the behavior of AutoMock when calling a method.

The first argument is the method name. You can also specify nested names with
`->`. A call in the middle of a method chain is regarded as a field and
can not be defined as a method at the same time. For example, if you try to
specify `'get_object->name'` and `'get_object'` as the same mock,
you'll get an error.

The second argument specifies the return value when the method is called.
If you specify a code reference, that code will be called on method invocation.
Be aware that `$self` is not included in the argument.

## automock\_isa

    $mock->automock_isa('Foo', 'Hoge');

Specify the superclass of the mock. This specification only affects the `isa`
method. It is convenient when argument is checked like [Moose](https://metacpan.org/pod/Moose) field.

## automock\_child

    # return the $mock->some_field
    $mock->automock_child('some_field');

Return the mock's child. Since this call is not recorded, it is convenient when
you want to avoid recording unnecessary calls when writing assertions.

TODO: Support `->` notations.

## automock\_calls

    my @calls = $mock->automock_calls;

Returns all recorded method calls. The element of "calls" is a two-element
array-ref. The first element is a method name, and the second element is an
array-ref representing arguments.

Method calls to children are also recorded in `$mock`. For example, calling
`$mock->child->do_it` will record two calls `'child'` and
`'child->do_it'`.

## automock\_reset

Erase all recorded method calls. Delete all method call history from descendant
mocks as well. It is used when you want to reuse mock.

## automock\_called\_ok

    $mock->automock_called_ok('hoge->bar');

Checks if the method was called. It is supposed to be used with [Test::More](https://metacpan.org/pod/Test::More) .

## automock\_called\_with\_ok

    $mock->automock_called_with_ok(
        'hoge->bar', [10, 20],
    );

Checks if the method was called with specified arguments.

## automock\_not\_called\_ok

    $mock->automock_not_called_ok('hoge->bar');

Checks if the method was not called.

# LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Honma <hiratara@cpan.org>
