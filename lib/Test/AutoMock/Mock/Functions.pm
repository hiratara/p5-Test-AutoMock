BEGIN {
    # A hack to suppress redefined warning caused by circulation dependency
    $INC{'Test/AutoMock/Mock/Functions.pm'} //= do {
        require File::Spec;
        File::Spec->rel2abs(__FILE__);
    };
}

package Test::AutoMock::Mock::Functions;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(blessed);

# Load classes after @EXPORT_OK creation
BEGIN { our @EXPORT_OK = qw(new_mock get_manager) }
use Test::AutoMock::Manager;
use Test::AutoMock::Mock::Basic;
use Test::AutoMock::Mock::Overloaded;

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
