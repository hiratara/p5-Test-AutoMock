package Test::LazyMock::TieHash;
use strict;
use warnings;
use parent qw(Test::LazyMock::Overloaded);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $self_fields = $self->_get_fields;
    $self_fields->{_lazymock_tie_hash} = {};

    $self;
}

sub _get_hashref {
    my $self = shift;
    my $self_fields = $self->_get_fields;
    $self_fields->{_lazymock_tie_hash};
}

sub TIEHASH {
    my ($class, $name, $parent) = @_;

    $class->new(
        name => $name,
        parent => $parent,
    );
}

sub FETCH {
    my ($self, $key) = @_;
    my $method_name = "{$key}";
    $self->_call_method($method_name, [], sub {
        my $self = shift;
        my $hashref = $self->_get_hashref;
        $hashref->{$key} = $self->lazymock_child($method_name)
                                                unless exists $hashref->{$key};
        $hashref->{$key};
    });
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->_call_method("{$key}", [$value], sub {
        my ($self, $value) = @_;
        $self->_get_hashref->{$key} = $value;
    });
}

sub DELETE {
    my ($self, $key) = @_;
    $self->_call_method("DELETE", [$key], sub {
        my ($self, $key) = @_;
        delete $self->_get_hashref->{$key};
    });
}

sub CLEAR {
    my $self = shift;
    $self->_call_method("CLEAR", [], sub {
        my $self = shift;
        %{$self->_get_hashref} = ();
    });
}

sub EXISTS {
    my ($self, $key) = @_;
    $self->_call_method('EXISTS', [$key], sub {
        my ($self, $key) = @_;
        exists $self->_get_hashref->{$key};
    });
}

sub FIRSTKEY {
    my $self = shift;
    $self->_call_method('FIRSTKEY', [], sub {
        my $self = shift;
        my $hashref = $self->_get_hashref;
        keys %$hashref;  # reset each() iterator
        each %$hashref;
    });
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    $self->_call_method('NEXTKEY', [$lastkey], sub {
        my $self = shift;
        each %{$self->_get_hashref};
    });
}

sub SCALAR {
    my $self = shift;
    $self->_call_method('SCALAR', [], sub {
        my $self = shift;
        scalar %{$self->_get_hashref};
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
