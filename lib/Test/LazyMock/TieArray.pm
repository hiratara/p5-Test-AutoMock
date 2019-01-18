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

    $self->_record_call($method_name, []);

    my $arrayref = $self->_get_arrayref;

    $arrayref->[$key] = $self->lazymock_child($method_name)
                                               unless exists $arrayref->[$key];

    $arrayref->[$key];
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $method_name = "[$key]";

    $self->_record_call($method_name, [$value]);

    $self->_get_arrayref->[$key] = $value;
}

sub FETCHSIZE {
    my $self = shift;

    $self->_record_call('FETCHSIZE', []);

    $#{$self->_get_arrayref} + 1;
}

sub STORESIZE {
    my ($self, $count) = @_;

    $self->_record_call('STORESIZE', [$count]);

    $#{$self->_get_arrayref} = $count - 1;
}

sub CLEAR {
    my $self = shift;

    $self->_record_call('CLEAR', []);

    @{$self->_get_arrayref} = ();
}

sub PUSH {
    my ($self, @list) = @_;

    $self->_record_call('PUSH', \@list);

    push @{$self->_get_arrayref}, @list;
}

sub POP {
    my $self = shift;

    $self->_record_call('POP', []);

    pop @{$self->_get_arrayref};
}

sub SHIFT {
    my $self = shift;

    $self->_record_call('SHIFT', []);

    shift @{$self->_get_arrayref};
}

sub UNSHIFT {
    my ($self, @list) = @_;

    $self->_record_call('UNSHIFT', \@list);

    unshift @{$self->_get_arrayref}, @list;
}

sub SPLICE {
    my ($self, $offset, $length, @list) = @_;

    $self->_record_call('SPLICE', [$offset, $length, @list]);

    splice @{$self->_get_arrayref}, $offset, $length, @list;
}

# sub EXTEND {
#     my ($self, $count) = @_;
#     # NOP
# }

sub DELETE {
    my ($self, $key) = @_;

    $self->_record_call('DELETE', [$key]);

    delete $self->_get_arrayref->[$key];
}

sub EXISTS {
    my ($self, $key) = @_;

    $self->_record_call('EXISTS', [$key]);

    exists $self->_get_arrayref->[$key];
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
