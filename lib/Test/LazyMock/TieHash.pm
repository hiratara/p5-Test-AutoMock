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

    $self->_record_call($method_name, []);

    $self->_get_hashref->{$key} //= $self->lazymock_child($method_name);
}

sub STORE {
    my ($self, $key, $value) = @_;
    my $method_name = "{$key}";

    $self->_record_call($method_name, [$value]);

    $self->_get_hashref->{$key} = $value;
}

sub DELETE {
    my ($self, $key) = @_;

    $self->_record_call('DELETE', [$key]);

    delete $self->_get_hashref->{$key};
}

sub CLEAR {
    my $self = shift;

    $self->_record_call('CLEAR', []);

    %{$self->_get_hashref} = ();
}

sub EXISTS {
    my ($self, $key) = @_;

    $self->_record_call('EXISTS', [$key]);

    exists $self->_get_hashref->{$key};
}

sub FIRSTKEY {
    my $self = shift;

    $self->_record_call('FIRSTKEY', []);

    my $hashref = $self->_get_hashref;
    keys %$hashref;  # reset each() iterator
    each %$hashref;
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;

    $self->_record_call('NEXTKEY', [$lastkey]);

    each %{$self->_get_hashref};
}

sub SCALAR {
    my $self = shift;

    $self->_record_call('SCALAR', []);

    scalar %{$self->_get_hashref};
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
