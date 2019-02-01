package Test::AutoMock::Overloaded;
use strict;
use warnings;
use overload (
    '${}' => sub { _overload_nomethod(@_, '${}') },
    '@{}' => \&_deref_array,
    '%{}' => \&_deref_hash,
    '&{}' => \&_deref_code,
    '*{}' => sub { _overload_nomethod(@_, '*{}') },
    nomethod => \&_overload_nomethod,
    fallback => 0,
);
use parent qw(Test::AutoMock);
use Test::AutoMock::Overloaded::TieArray;
use Test::AutoMock::Overloaded::TieHash;

my %default_overload_handlers = (
    '+' => undef,
    '-' => undef,
    '*' => undef,
    '/' => undef,
    '%' => undef,
    '**' => undef,
    '<<' => undef,
    '>>' => undef,
    'x' => undef,
    '.' => undef,

    '+=' => sub { $_[0] },
    '-=' => sub { $_[0] },
    '*=' => sub { $_[0] },
    '/=' => sub { $_[0] },
    '%=' => sub { $_[0] },
    '**=' => sub { $_[0] },
    '<<=' => sub { $_[0] },
    '>>=' => sub { $_[0] },
    'x=' => sub { $_[0] },
    '.=' => sub { $_[0] },

    '<' => undef,
    '<=' => undef,
    '>' => undef,
    '>=' => undef,
    '==' => undef,
    '!=' => undef,

    '<=>' => undef,
    'cmp' => undef,

    'lt' => undef,
    'le' => undef,
    'gt' => undef,
    'ge' => undef,
    'eq' => undef,
    'ne' => undef,

    '&' => undef,
    '&=' => sub { $_[0] },
    '|' => undef,
    '|=' => sub { $_[0] },
    '^' => undef,
    '^=' => sub { $_[0] },
    # '&.' => undef,
    # '&.=' => sub { $_[0] },
    # '|.' => undef,
    # '|.=' => sub { $_[0] },
    # '^.' => undef,
    # '^.=' => sub { $_[0] },

    'neg' => undef,
    '!' => undef,
    '~' => undef,
    # '~.' => sub { $_[0] },

    '++' => sub { $_[0] },
    '--' => sub { $_[0] },

    'atan2' => undef,
    'cos' => undef,
    'sin' => undef,
    'exp' => undef,
    'abs' => undef,
    'log' => undef,
    'sqrt' => undef,
    'int' => undef,

    'bool' => sub { !! 1 },
    '""' => sub {
        my $self = shift;
        $self->_exec_without_overloads(sub { "$self" });
    },
    '0+' => sub { 1 },
    'qr' => sub { qr// },

    '<>' => sub { undef },

    '-X' => undef,

    # '~~' => sub { !! 1 },

    '${}' => sub { \ my $x },
    '*{}' => sub { \*DUMMY },
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $self_fields = $self->_get_fields;

    $self_fields->{_lazymock_tie_hash} = do {
        tie my %h, 'Test::AutoMock::Overloaded::TieHash', $self;
        \%h;
    };
    $self_fields->{_lazymock_tie_array} = do {
        tie my @arr, 'Test::AutoMock::Overloaded::TieArray', $self;
        \@arr;
    };

    $self;
}

my $x = 0;
sub _overload_nomethod {
    my ($self, $other, $is_swapped, $operator, $is_numeric) = @_;

    # don't record the call of copy constructor (and don't copy mocks)
    return $self if $operator eq '=';

    my $operator_name = "`$operator`";
    my $default_handler;
    if (exists $default_overload_handlers{$operator}) {
        $default_handler = $default_overload_handlers{$operator};
    } else {
        warn "unknown operator: $operator";
    }

    $self->_call_method(
        $operator_name => [$other, $is_swapped],
        $default_overload_handlers{$operator},
    );
}

sub _deref_hash {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    # don't record `%{}` calls

    $self_fields->{_lazymock_tie_hash}
}

sub _deref_array {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    # don't record `@{}` calls

    $self_fields->{_lazymock_tie_array};
}

sub _deref_code {
    my $self = shift;

    # don't record `&{}` calls

    sub {
        my @args = @_;
        $self->_call_method('()', [@_], undef);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Overloaded - AutoMock that supports operator overloading

=head1 SYNOPSIS

    use Test::AutoMock::Overloaded;
    use Test::More;

    my $mock = Test::AutoMock::Overloaded->new;

    # define operators, hashes, arrays
    $mock->automock_add_method('`+`' => 10);
    $mock->automock_add_method('{key}' => 'value');
    $mock->automock_add_method('[0]' => 'zero');

    # call overloaded operators
    is($mock + 5, 10);
    is($mock->{key}, 'value');
    is($mock->[0], 'zero');

    # varify calls
    $mock->automock_called_with_ok('`+`', [5, '']);
    $mock->automock_called_ok('{key}');
    $mock->automock_called_ok('[0]');

=head1 DESCRIPTION

It is a subclass of AutoMock that supports operator overloading.

=head1 SPECIAL METHODS

This class supports special notation methods. It can be used with methods such
as C<automock_called_ok> and C<automock_add_method>.

=head2 OPERATOR OVERLOADING

The method name enclosed in backtick(C<`>) means operator overloading. The
operator name is the same as the L<overload> module.

Most operator overloads return child AutoMock, just like regular methods.
The following methods return default values that match type. Please overwrite
it if necessary.

=over 4

=item C<`bool`> : C<!!1>

=item C<`""`> : a unique name of instance

=item C<`0+`> : C<1>

=item C<`qr`> : C<qr//>

=back

Also, in order to avoid infinite loops, C<< `<>` >> defaults to C<undef>.

There are two arguments to be recorded, C<$other> and C<$swap>, according to the
L<overload> module specifications. Please be careful when using
C<automock_called_with_ok>.

Below is a complete list of possible names.

=over 4

=item C<`+`>, C<`-`>, C<`*`>, C<`/`>, C<`%`>, C<`**`>, C<`<<`>, C<<< `>>` >>>, C<`x`>, C<`.`>

=item C<`+=`>, C<`-=`>, C<`*=`>, C<`/=`>, C<`%=`>, C<`**=`>, C<`<<=`>, C<<< `>>=` >>>, C<`x=`>, C<`.=`>

=item C<`<`>, C<`<=`>, C<< `>` >>, C<< `>=` >>, C<`==`>, C<`!=`>

=item C<< `<=>` >>, C<`cmp`>

=item C<`lt`>, C<`le`>, C<`gt`>, C<`ge`>, C<`eq`>, C<`ne`>

=item C<`&`>, C<`&=`>, C<`|`>, C<`|=`>, C<`^`>, C<`^=`>

=item C<`neg`>, C<`!`>, C<`~`>

=item C<`++`>, C<`--`>

=item C<`atan2`>, C<`cos`>, C<`sin`>, C<`exp`>, C<`abs`>, C<`log`>, C<`sqrt`>, C<`int`>

=item C<`bool`>, C<`""`>, C<`0+`>, C<`qr`>

=item C<< `<>` >>

=item C<`-X`>

=item C<`${}`>, C<`*{}`>

=back

C<@{}> and C<%{}>, C<&{}> are not supported. see L<"HASH, ARRAY, CODE ACCESS">
instead.

=head2 HASH, ARRAY, CODE ACCESS

In this class, you can handle operations with the same notation as hash-ref,
array-ref, code-ref.

=over 4

=item C<[index]>, C<FETCHSIZE>, C<STORESIZE>, C<CLEAR>, C<PUSH>, C<POP>, C<SHIFT>, C<UNSHIFT>, C<DELETE>, C<EXISTS>

This name is used when the mock is called as an array reference.
See L<Test::AutoMock::Overloaded::TieArray> for details.

=item C<{key}>, C<DELETE>, C<CLEAR>, C<EXISTS>, C<FIRSTKEY>, C<NEXTKEY>, C<SCALAR>

This name is used when the mock is called as an hash reference.
See L<Test::AutoMock::Overloaded::TieHash> for details.

=item C<()>

This name is used when the mock is called as a code reference. You can also
access its arguments.

=back

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

