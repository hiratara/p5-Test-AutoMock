package Test::AutoMock::Proxy::Functions;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(new_proxy get_manager);

sub new_proxy ($) {
    my $manager = shift;

    my $proxy_class = $manager->{proxy_class} // 'Test::AutoMock::Proxy::Basic';
    bless \$manager, $proxy_class;
}

sub get_manager ($) {
    my $proxy = shift;

    my $class = blessed $proxy or die '$proxy is not an object';
    bless $proxy, __PACKAGE__;  # disable operator overloads
    my $deref = eval { $$proxy };
    bless $proxy, $class;
    $@ and die $@;

    $deref;
}

1;
