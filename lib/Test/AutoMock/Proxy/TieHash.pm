package Test::AutoMock::Proxy::TieHash;
use strict;
use warnings;
use Scalar::Util qw(weaken);

sub new {
    my ($class, $lazy_mock) = @_;

    my $self = [{}, $lazy_mock];
    weaken($self->[1]);  # avoid cyclic reference

    bless $self => $class;
}

sub TIEHASH {
    my ($class, $lazy_mock) = @_;

    $class->new($lazy_mock);
}

sub FETCH {
    my ($self, $key) = @_;
    my ($hashref, $lazy_mock) = @$self;
    my $method_name = "{$key}";

    $lazy_mock->_call_method($method_name, [], sub {
        my $self = shift;
        $hashref->{$key} = $self->child($method_name)->proxy
                                                unless exists $hashref->{$key};
        $hashref->{$key};
    });
}

sub STORE {
    my ($self, $key, $value) = @_;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method("{$key}", [$value], sub {
        my ($self, $value) = @_;
        $hashref->{$key} = $value;
    });
}

sub DELETE {
    my ($self, $key) = @_;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method("DELETE", [$key], sub {
        my ($self, $key) = @_;
        delete $hashref->{$key};
    });
}

sub CLEAR {
    my $self = shift;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method("CLEAR", [], sub {
        my $self = shift;
        %$hashref = ();
    });
}

sub EXISTS {
    my ($self, $key) = @_;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method('EXISTS', [$key], sub {
        my ($self, $key) = @_;
        exists $hashref->{$key};
    });
}

sub FIRSTKEY {
    my $self = shift;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method('FIRSTKEY', [], sub {
        my $self = shift;
        keys %$hashref;  # reset each() iterator
        each %$hashref;
    });
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method('NEXTKEY', [$lastkey], sub {
        my $self = shift;
        each %$hashref;
    });
}

sub SCALAR {
    my $self = shift;
    my ($hashref, $lazy_mock) = @$self;

    $lazy_mock->_call_method('SCALAR', [], sub {
        my $self = shift;
        scalar %$hashref;
    });
}

# sub DESTROY {
#     my $self = shift;
#     $self->SUPER::DESTROY(@_);
# }

# sub UNTIE {
#     my $self = shift;

#     # NOP
# }

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Overloaded::TieHash - Track operations to hash-ref

=head1 DESCRIPTION

This module is part of L<Test::AutoMock::Overloaded> and tracks operations to
hash-refs. You won't instantiate this class.

For the sake of simplicity, we use the notation C<{key}> for C<FETCH> and
C<STORE>. For other tie methods, record with the original name.

See https://perldoc.perl.org/perltie.html#Tying-Hashes .

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

