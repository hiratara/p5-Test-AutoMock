use strict;
use warnings;
use Test::LazyMock::Overloaded;
use Test::More import => [qw(is done_testing)];

my $mock = Test::LazyMock::Overloaded->new(
    'hoge->bar' => sub { 1 },
);

is $mock->hoge->bar(10, 20), 1;

$mock->lazymock_called_with_ok(
    'hoge->bar', [10, 20],
);
$mock->lazymock_called_ok('hoge->bar');
$mock->lazymock_not_called_ok('bar');

my $hoge = $mock->lazymock_child('hoge');
$hoge->lazymock_called_with_ok(
    'bar', [10, 20],
);
$hoge->lazymock_not_called_ok('hoge');

done_testing;
