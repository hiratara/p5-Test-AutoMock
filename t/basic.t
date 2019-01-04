use strict;
use warnings;
use Test::More import => [qw(is is_deeply done_testing)];
use Test::LazyMock;

my $mock = Test::LazyMock->new;
# mock.hoge.return_value = 10
$mock->lazymock_add_method(hoge => 10);
# mock.foo.side_effect = lambda x: x + 1
$mock->lazymock_add_method(foo => sub { $_[0] + 1 });

# call any methods
$mock->abc;
$mock->def->ghi;

# call defined methods
is $mock->hoge, 10;
is $mock->foo(100), 101;

# assert results
my @calls = $mock->lazymock_calls;
is @calls, 5;
is_deeply $calls[0], ['abc', []];
is_deeply $calls[1], ['def', []];
is_deeply $calls[2], ['def->ghi', []];
is_deeply $calls[3], ['hoge', []];
is_deeply $calls[4], ['foo', [100]];

# assert sub results
my @def_calls = $mock->def->lazymock_calls;
is @def_calls, 1;
is_deeply $def_calls[0], ['ghi', []];

# resets all call records
$mock->lazymock_reset;

# assert sub results
my @def_calls_after_reset = $mock->def->lazymock_calls;
is @def_calls_after_reset, 0;

# assert results again
my @calls_after_reset = $mock->lazymock_calls;
is @calls_after_reset, 1, "TODO: want not to record a def call";
is_deeply $calls_after_reset[0], ['def', []];

done_testing;
