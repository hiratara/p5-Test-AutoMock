use strict;
use warnings;
use Test::More import => [qw(is done_testing)];
use Test::LazyMock;

my $mock = Test::LazyMock->new(
    methods => {
        'hoge->bar' => sub { 'bar' },
        'hoge->boo' => 'boo',
        'foo->hoge' => sub { 'hoge' },
        'abc->def->ghi' => sub { 'ghi' },
    },
);

$mock->lazymock_add_method('foo->bar' => 'bar');
$mock->lazymock_add_method('abc->jkl' => sub { "jkl$_[0]" });

is $mock->hoge->bar, 'bar';
is $mock->hoge->boo, 'boo';
is $mock->foo->hoge, 'hoge';
is $mock->abc->def->ghi, 'ghi';
is $mock->foo->bar, 'bar';
is $mock->abc->jkl('JKL'), 'jklJKL';

done_testing;
