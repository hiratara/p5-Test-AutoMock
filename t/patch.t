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

patch_sub {
    my $mock = shift;
    _call_my_client;
    is_deeply [map { $_->[0] } $mock->lazymock_calls],
              [qw(get get->is_success get->is_success->`bool` get->content)];
} qw(MyClient::new);

{
    my $res = _call_my_client;
    is "$res", "BODY\n", "undo patches";
}

patch_sub {
    my $mock = shift;
    MyClient->method_not_found->ok;
    my @calls = $mock->lazymock_calls;
    is @calls, 1;
    is $calls[0][0], 'ok';
} qw(MyClient::method_not_found);

my $ret = eval { MyClient->method_not_found; 1 };
my $exception = $@;
ok ! $ret, 'remove patched methods';
like $@, qr/\bcan't locate object method\b/i;

patch_sub {
    my ($hoge_mock, $bar_mock) = @_;
    Hoge->new->hoge;
    Bar->new->bar;

    my @hoge_calls = $hoge_mock->lazymock_calls;
    is @hoge_calls, 1;
    is $hoge_calls[0][0], 'hoge';

    my @bar_calls = $bar_mock->lazymock_calls;
    is @bar_calls, 1;
    is $bar_calls[0][0], 'bar';
} qw(Hoge::new Bar::new);

{
    no warnings 'once';
    is *Hoge::new{CODE}, undef, 'remove pathced methods (1)';
    is *Bar::new{CODE}, undef, 'remove pathced methods (2)';
}

done_testing;
