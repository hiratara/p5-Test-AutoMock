use strict;
use warnings;
use Test::More import => [qw(is like done_testing)];
use Test::AutoMock;

{
    my $mock = Test::AutoMock->new;

    my $ret_invalid = eval { $mock->automock_hoge; 1 };
    like $@, qr/"automock_hoge" is reserved/;
    is $ret_invalid, undef;

    my $ret_private = eval { $mock->_hoge; 1 };
    like $@, qr/"_hoge" is reserved/;
    is $ret_private, undef;
}

{
    my $mock = Test::AutoMock->new(
        allow_any_method => 1,
    );

    my $ret_invalid = eval { $mock->automock_hoge; 1 };
    is $ret_invalid, 1;

    my $ret_private = eval { $mock->_hoge; 1 };
    is $ret_private, 1;
}

done_testing;
