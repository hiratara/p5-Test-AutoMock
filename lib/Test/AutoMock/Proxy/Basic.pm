package Test::AutoMock::Proxy::Basic;
use strict;
use warnings;
use Scalar::Util ();
use Test::AutoMock::Proxy::Functions qw(get_manager);

sub isa {
    my $class_or_self = shift;
    my ($name) = @_;

    # don't look for isa if $self is a class name
    if (Scalar::Util::blessed $class_or_self) {
        my $manager = get_manager $class_or_self;
        return 1 if $manager->{isa}{$name};
    }

    $class_or_self->SUPER::isa(@_);
}

sub DESTROY {}

sub AUTOLOAD {
    my ($self, @params) = @_;
    (my $meth = our $AUTOLOAD) =~ s/.*:://;

    my $manager = get_manager $self;
    $manager->_call_method($self, $meth => \@params, undef);
}

1;
