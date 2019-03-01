package Test::AutoMock::Mock::TieHash;
use strict;
use warnings;

sub TIEHASH {
    my ($class, $manager) = @_;

    bless \$manager => $class;
}

sub FETCH {
    my ($self, $key) = @_;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;
    my $method_name = "{$key}";

    $manager->_call_method($self, $method_name, [], sub {
        my $self = shift;
        $hashref->{$key} = $manager->child($method_name)->mock
                                                unless exists $hashref->{$key};
        $hashref->{$key};
    });
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, "{$key}", [$value], sub {
        my ($self, $value) = @_;
        $hashref->{$key} = $value;
    });
}

sub DELETE {
    my ($self, $key) = @_;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, "DELETE", [$key], sub {
        my ($self, $key) = @_;
        delete $hashref->{$key};
    });
}

sub CLEAR {
    my $self = shift;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, "CLEAR", [], sub {
        my $self = shift;
        %$hashref = ();
    });
}

sub EXISTS {
    my ($self, $key) = @_;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, 'EXISTS', [$key], sub {
        my ($self, $key) = @_;
        exists $hashref->{$key};
    });
}

sub FIRSTKEY {
    my $self = shift;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, 'FIRSTKEY', [], sub {
        my $self = shift;
        keys %$hashref;  # reset each() iterator
        each %$hashref;
    });
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, 'NEXTKEY', [$lastkey], sub {
        my $self = shift;
        each %$hashref;
    });
}

sub SCALAR {
    my $self = shift;
    my $manager = $$self;
    my $hashref = $manager->tie_hash;

    $manager->_call_method($self, 'SCALAR', [], sub {
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

