package Test::AutoMock::Proxy::Basic;
use strict;
use warnings;
use Scalar::Util ();
use Test::AutoMock::ProxyStore qw(%Proxy_To_Manager);

sub isa {
    my $class_or_self = shift;
    my ($name) = @_;

    # don't look for isa if $self is a class name
    if (Scalar::Util::blessed $class_or_self) {
        my $manager = $Proxy_To_Manager{Scalar::Util::refaddr $class_or_self};
        return 1 if $manager->{isa}{$name};
    }

    $class_or_self->SUPER::isa(@_);
}

sub DESTROY {
    my $self = shift;
    delete $Proxy_To_Manager{Scalar::Util::refaddr $self};
}

sub AUTOLOAD {
    my ($self, @params) = @_;
    (my $meth = our $AUTOLOAD) =~ s/.*:://;

    my $manager = $Proxy_To_Manager{Scalar::Util::refaddr $self};
    $manager->_call_method($meth => \@params, undef);
}

1;
