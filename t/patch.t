use strict;
use warnings;
use lib './t/lib';
use MyClient;
use Test::LazyMock::Patch qw(patch_sub);
use Test::More import => [qw(ok is is_deeply like done_testing)];

sub _call_my_client () {
    my $client = MyClient->new;
    my $res = $client->get;

    $res->is_success ? $res->content : undef;
}

patch_sub 'MyClient::new' => sub {
    my $mock = shift;
    _call_my_client;
    is_deeply [map { $_->[0] } $mock->lazymock_calls],
              [qw(get get->is_success get->is_success->`bool` get->content)];
};

{
    my $res = _call_my_client;
    is "$res", "BODY\n", "undo patches";
}

patch_sub 'MyClient::method_not_found' => sub {
    my $mock = shift;
    MyClient->method_not_found->ok;
    my @calls = $mock->lazymock_calls;
    is @calls, 1;
    is $calls[0][0], 'ok';
};

my $ret = eval { MyClient->method_not_found; 1 };
my $exception = $@;
ok ! $ret, 'remove patched methods';
like $@, qr/\bcan't locate object method\b/i;

done_testing;
