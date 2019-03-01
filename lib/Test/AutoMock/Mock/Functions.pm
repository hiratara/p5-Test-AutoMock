package Test::AutoMock::Mock::Functions;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(blessed);

# Load classes after @EXPORT_OK creation
our @EXPORT_OK = qw(new_mock get_manager);
require Test::AutoMock::Manager;
require Test::AutoMock::Mock::Basic;
require Test::AutoMock::Mock::Overloaded;

sub new_mock ($@) {
    my $class = shift;

    my $mock = bless(\ my $manager, $class);
    $manager = Test::AutoMock::Manager->new(
        @_,
        mock_class => $class,
        mock => $mock,
    );

    $mock;
}

sub get_manager ($) {
    my $mock = shift;

    my $class = blessed $mock or die '$mock is not an object';

    bless $mock, __PACKAGE__ . "::Dummy";  # disable operator overloads
    my $deref = eval { $$mock };

    bless $mock, $class;
    $@ and die $@;

    $deref;
}

1;
