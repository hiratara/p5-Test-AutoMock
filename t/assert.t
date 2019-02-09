use strict;
use warnings;
use Test::AutoMock::Overloaded;
use Test::More import => [qw(is done_testing)];

my $mock = Test::AutoMock::Overloaded->new(
    'hoge->bar' => sub { 1 },
);

is $mock->hoge->bar(10, 20), 1;

$mock->automock_called_with_ok(
    'hoge->bar', [10, 20],
);
$mock->automock_called_ok('hoge->bar');
$mock->automock_not_called_ok('bar');

my $hoge = $mock->automock_child('hoge');
$hoge->automock_called_with_ok(
    'bar', [10, 20],
);
$hoge->automock_not_called_ok('hoge');

done_testing;
