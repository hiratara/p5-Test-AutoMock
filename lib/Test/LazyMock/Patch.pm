package Test::LazyMock::Patch;
use strict;
use warnings;
use Exporter qw(import);
use Test::LazyMock::Overloaded;

our @EXPORT_OK = qw(patch_sub);

sub patch_sub {
    my ($subroutine, $code) = @_;

    my $mock = Test::LazyMock::Overloaded->new;
    {
        no strict 'refs';
        no warnings 'redefine';
        local *$subroutine = sub { $mock };
        $code->($mock);
    }
}

1;
