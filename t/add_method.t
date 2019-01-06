use strict;
use warnings;
use Test::More import => [qw(ok is like note done_testing)];
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

{
    my $ret = eval {
        $mock->lazymock_add_method('abc->def' => 'def');
        1;
    };
    like $@, qr/`def` has already been defined as a field\b/;
    is $ret, undef;
}

{
    my $ret = eval {
        $mock->lazymock_add_method('abc->def->ghi->jkl' => 'jkl');
        1;
    };
    like $@, qr/`ghi` has already been defined as a method\b/;
    is $ret, undef;
}

{
    my $ret = eval {
        $mock->lazymock_add_method('hoge->bar' => 'bar');
        1;
    };
    like $@, qr/`bar` has already been defined as a method\b/;
    is $ret, undef;
}

is $mock->hoge->bar, 'bar';
is $mock->hoge->boo, 'boo';
is $mock->foo->hoge, 'hoge';
is $mock->abc->def->ghi, 'ghi';
is $mock->foo->bar, 'bar';
is $mock->abc->jkl('JKL'), 'jklJKL';

my $invalid_mock = eval {
    Test::LazyMock->new(
        methods => {
            'hoge->foo' => 'foo',
            'hoge->foo->bar' => 'bar',
        },
    );
};
ok $@ and note $@;
is $invalid_mock, undef;

done_testing;
