package Test::AutoMock::Overloaded::TieHash;
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
        $hashref->{$key} = $self->automock_child($method_name)
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
