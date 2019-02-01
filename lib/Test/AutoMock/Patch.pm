package Test::AutoMock::Patch;
use strict;
use warnings;
use Exporter qw(import);
use Test::AutoMock::Overloaded;

our @EXPORT_OK = qw(patch_sub);

sub _patch_sub_one {
    my ($code, $subroutines, $mocks) = @_;
    my ($subroutine, @left_subroutines) = @$subroutines;

    my $mock = Test::AutoMock::Overloaded->new;
    my @new_mocks = (@$mocks, $mock);

    no strict 'refs';
    no warnings 'redefine';
    local *$subroutine = sub { $mock };

    @left_subroutines
        ? _patch_sub_one($code, \@left_subroutines, \@new_mocks)
        : $code->(@new_mocks);
}

sub patch_sub (&@) {
    my ($code, @subroutines) = @_;
    _patch_sub_one $code, \@subroutines, [];
}

1;
