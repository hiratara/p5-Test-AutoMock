package Test::LazyMock::TieArray;
use strict;
use warnings;
use parent qw(Test::LazyMock::Overloaded);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $self_fields = $self->_get_fields;
    $self_fields->{_lazymock_tie_array} = [];

    $self;
}


sub _get_arrayref {
    my $self = shift;
    my $self_fields = $self->_get_fields;
    $self_fields->{_lazymock_tie_array};
}

sub TIEARRAY {
    my ($class, $name, $parent) = @_;

    $class->new(
        name => $name,
        parent => $parent,
    );
}

sub FETCH {
    my ($self, $key) = @_;
    my $method_name = "[$key]";
    $self->_call_method($method_name, [], sub {
        my $self = shift;
        my $arrayref = $self->_get_arrayref;
        $arrayref->[$key] = $self->lazymock_child($method_name)
                                               unless exists $arrayref->[$key];
        $arrayref->[$key];
    });
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->_call_method("[$key]", [$value], sub {
        my ($self, $value) = @_;
        $self->_get_arrayref->[$key] = $value;
    });
}

sub FETCHSIZE {
    my $self = shift;
    $self->_call_method('FETCHSIZE', [], sub {
        my $self = shift;
        $#{$self->_get_arrayref} + 1;
    });
}

sub STORESIZE {
    my ($self, $count) = @_;
    $self->_call_method('STORESIZE', [$count], sub {
        my ($self, $count) = @_;
        $#{$self->_get_arrayref} = $count - 1;
    });
}

sub CLEAR {
    my $self = shift;
    $self->_call_method('CLEAR', [], sub {
        my $self = shift;
        @{$self->_get_arrayref} = ();
    });
}

sub PUSH {
    my ($self, @list) = @_;
    $self->_call_method('PUSH', \@list, sub {
        my ($self, @list) = @_;
        push @{$self->_get_arrayref}, @list;
    });
}

sub POP {
    my $self = shift;
    $self->_call_method('POP', [], sub {
        my $self = shift;
        pop @{$self->_get_arrayref};
    });
}

sub SHIFT {
    my $self = shift;
    $self->_call_method('SHIFT', [], sub {
        my $self = shift;
        shift @{$self->_get_arrayref};
    });
}

sub UNSHIFT {
    my ($self, @list) = @_;
    $self->_call_method('UNSHIFT', \@list, sub {
        my ($self, @list) = @_;
        unshift @{$self->_get_arrayref}, @list;
    });
}

sub SPLICE {
    my ($self, $offset, $length, @list) = @_;

    $self->_call_method('SPLICE', [$offset, $length, @list], sub {
        my ($self, $offset, $length, @list) = @_;
        splice @{$self->_get_arrayref}, $offset, $length, @list;
    });
}

# sub EXTEND {
#     my ($self, $count) = @_;
#     # NOP
# }

sub DELETE {
    my ($self, $key) = @_;
    $self->_call_method('DELETE', [$key], sub {
        my ($self, $key) = @_;
        delete $self->_get_arrayref->[$key];
    });
}

sub EXISTS {
    my ($self, $key) = @_;

    $self->_call_method('EXISTS', [$key], sub {
        my ($self, $key) = @_;
        exists $self->_get_arrayref->[$key];
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
