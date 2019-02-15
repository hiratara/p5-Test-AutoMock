use strict;
use warnings;
use Test::More import => [qw(ok isa_ok done_testing)];
use Test::AutoMock qw(mock manager);

{
    my $mock = mock(
        isa => 'Hoge',
    );
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Test::AutoMock::Proxy::Basic';
    ok ! $mock->isa('Foo'), '$mock is not a Foo class';
}

{
    my $mock = mock(
        isa => ['Foo', 'Hoge'],
    );
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Foo';
    isa_ok $mock, 'Test::AutoMock::Proxy::Basic';
    ok ! $mock->isa('Bar'), '$mock is not a Bar class';
}

{
    my $mock = mock(isa => 'Bar');
    manager($mock)->isa('Foo', 'Hoge');
    isa_ok $mock, 'Hoge';
    isa_ok $mock, 'Foo';
    isa_ok $mock, 'Test::AutoMock::Proxy::Basic';
    ok ! $mock->isa('Bar'), '$mock is not a Bar class';
}

{
    isa_ok 'Test::AutoMock::Proxy::Basic', 'Test::AutoMock::Proxy::Basic', 'reflexive property';
    ok ! Test::AutoMock::Proxy::Basic->isa('Hoge'), 'Proxy is not a Hoge class';
}

done_testing;
