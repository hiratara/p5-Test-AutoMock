use strict;
use warnings;
use Test::More import => [qw(ok isa_ok done_testing)];
use Test::LazyMock;

{
    my $mock = Test::LazyMock->new(
        isa => 'Hoge',
    );
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Test::LazyMock';
    ok ! $mock->isa('Foo'), '$mock is not a Foo class';
}

{
    my $mock = Test::LazyMock->new(
        isa => ['Foo', 'Hoge'],
    );
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Foo';
    isa_ok $mock, 'Test::LazyMock';
    ok ! $mock->isa('Bar'), '$mock is not a Bar class';
}

{
    my $mock = Test::LazyMock->new(isa => 'Bar');
    $mock->lazymock_isa('Foo', 'Hoge');
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Foo';
    isa_ok $mock, 'Test::LazyMock';
    ok ! $mock->isa('Bar'), '$mock is not a Bar class';
}

{
    isa_ok 'Test::LazyMock', 'Test::LazyMock', 'reflexive property';
    ok ! Test::LazyMock->isa('Hoge'), 'LazyMOck is not a Hoge class';
}

done_testing;
