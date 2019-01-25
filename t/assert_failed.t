use strict;
use warnings;
use Test::Tester import => [qw(check_tests)]; # must be used at first
use Test::LazyMock::Overloaded;
use Test::More import => [qw(done_testing)];

my $mock = Test::LazyMock::Overloaded->new;
$mock->hoge(1, 2);

check_tests sub { $mock->lazymock_called_with_ok(hoge => [2, 1]) },
    [
        {
            ok => 0,
            name => 'hoge has been called with correct arguments',
            diag => '',
        },
    ];

check_tests sub { $mock->lazymock_called_ok('foo') },
    [
        {
            ok => 0,
            name => 'foo has been called',
            diag => '',
        },
    ];

check_tests sub { $mock->lazymock_not_called_ok('hoge') },
    [
        {
            ok => 0,
            name => 'hoge has not been called',
            diag => '',
        },
    ];

done_testing;
