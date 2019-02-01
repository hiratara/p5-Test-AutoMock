use strict;
use warnings;
use Test::More import => [qw(ok isa_ok done_testing)];
use Test::AutoMock;

{
    my $mock = Test::AutoMock->new(
        isa => 'Hoge',
    );
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Test::AutoMock';
    ok ! $mock->isa('Foo'), '$mock is not a Foo class';
}

{
    my $mock = Test::AutoMock->new(
        isa => ['Foo', 'Hoge'],
    );
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Foo';
    isa_ok $mock, 'Test::AutoMock';
    ok ! $mock->isa('Bar'), '$mock is not a Bar class';
}

{
    my $mock = Test::AutoMock->new(isa => 'Bar');
    $mock->automock_isa('Foo', 'Hoge');
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Foo';
    isa_ok $mock, 'Test::AutoMock';
    ok ! $mock->isa('Bar'), '$mock is not a Bar class';
}

{
    isa_ok 'Test::AutoMock', 'Test::AutoMock', 'reflexive property';
    ok ! Test::AutoMock->isa('Hoge'), 'LazyMOck is not a Hoge class';
}

done_testing;
