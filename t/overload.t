use strict;
use warnings;
use Test::More import => [qw(is is_deeply done_testing)];
use Test::LazyMock::Overloaded;

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    my (undef) = ($z + 0);
    my (undef) = ($z - 0);
    my (undef) = ($z * 1);
    my (undef) = ($z / 1);
    my (undef) = ($z % 1);
    my (undef) = ($z ** 1);
    my (undef) = ($z << 0);
    my (undef) = ($z >> 0);
    my (undef) = ($z x 1);
    my (undef) = ($z . '');

    my @calls = $mock->lazymock_calls;
    is @calls, 11;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`+`', [0, '']];
    is_deeply $calls[2], ['z->`-`', [0, '']];
    is_deeply $calls[3], ['z->`*`', [1, '']];
    is_deeply $calls[4], ['z->`/`', [1, '']];
    is_deeply $calls[5], ['z->`%`', [1, '']];
    is_deeply $calls[6], ['z->`**`', [1, '']];
    is_deeply $calls[7], ['z->`<<`', [0, '']];
    is_deeply $calls[8], ['z->`>>`', [0, '']];
    is_deeply $calls[9], ['z->`x`', [1, '']];
    is_deeply $calls[10], ['z->`.`', ['', '']];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    $z += 0;
    $z -= 0;
    $z *= 1;
    $z /= 1;
    $z %= 1;
    $z **= 1;
    $z <<= 0;
    $z >>= 0;
    $z x= 1;
    $z .= '';

    my @calls = $mock->lazymock_calls;
    is @calls, 11;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`+=`', [0, undef]];
    is_deeply $calls[2], ['z->`-=`', [0, undef]];
    is_deeply $calls[3], ['z->`*=`', [1, undef]];
    is_deeply $calls[4], ['z->`/=`', [1, undef]];
    is_deeply $calls[5], ['z->`%=`', [1, undef]];
    is_deeply $calls[6], ['z->`**=`', [1, undef]];
    is_deeply $calls[7], ['z->`<<=`', [0, undef]];
    is_deeply $calls[8], ['z->`>>=`', [0, undef]];
    is_deeply $calls[9], ['z->`x=`', [1, undef]];
    is_deeply $calls[10], ['z->`.=`', ['', undef]];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    my (undef) = ($z < 0);
    my (undef) = ($z <= 0);
    my (undef) = ($z > 0);
    my (undef) = ($z >= 0);
    my (undef) = ($z == 0);
    my (undef) = ($z != 0);

    my @calls = $mock->lazymock_calls;
    is @calls, 7;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`<`', [0, '']];
    is_deeply $calls[2], ['z->`<=`', [0, '']];
    is_deeply $calls[3], ['z->`>`', [0, '']];
    is_deeply $calls[4], ['z->`>=`', [0, '']];
    is_deeply $calls[5], ['z->`==`', [0, '']];
    is_deeply $calls[6], ['z->`!=`', [0, '']];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    my (undef) = ($z <=> 0);
    my (undef) = ($z cmp 0);

    my @calls = $mock->lazymock_calls;
    is @calls, 3;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`<=>`', [0, '']];
    is_deeply $calls[2], ['z->`cmp`', [0, '']];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    my (undef) = ($z lt '');
    my (undef) = ($z le '');
    my (undef) = ($z gt '');
    my (undef) = ($z ge '');
    my (undef) = ($z eq '');
    my (undef) = ($z ne '');

    my @calls = $mock->lazymock_calls;
    is @calls, 7;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`lt`', ['', '']];
    is_deeply $calls[2], ['z->`le`', ['', '']];
    is_deeply $calls[3], ['z->`gt`', ['', '']];
    is_deeply $calls[4], ['z->`ge`', ['', '']];
    is_deeply $calls[5], ['z->`eq`', ['', '']];
    is_deeply $calls[6], ['z->`ne`', ['', '']];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    my (undef) = ($z & 0xff);
    my (undef) = ($z &= 0xff);
    my (undef) = ($z | 0x00);
    my (undef) = ($z |= 0x00);
    my (undef) = ($z ^ 0x00);
    my (undef) = ($z ^= 0x00);
    # my (undef) = ($z &. "\xff");
    # my (undef) = ($z &.= "\xff");
    # my (undef) = ($z |. "\x00");
    # my (undef) = ($z |.= "\x00");
    # my (undef) = ($z ^. "\x00");
    # my (undef) = ($z ^.= "\x00");

    my @calls = $mock->lazymock_calls;
    is @calls, 7;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`&`', [0xff, '']];
    is_deeply $calls[2], ['z->`&=`', [0xff, undef]];
    is_deeply $calls[3], ['z->`|`', [0x00, '']];
    is_deeply $calls[4], ['z->`|=`', [0x00, undef]];
    is_deeply $calls[5], ['z->`^`', [0x00, '']];
    is_deeply $calls[6], ['z->`^=`', [0x00, undef]];
    # is_deeply $calls[7], ['z->`&.`', ["\xff", '']];
    # is_deeply $calls[8], ['z->`&.=`', ["\xff", undef]];
    # is_deeply $calls[9], ['z->`|.`', ["\x00", '']];
    # is_deeply $calls[10], ['z->`|.=`', ["\x00", undef]];
    # is_deeply $calls[11], ['z->`^.`', ["\x00", '']];
    # is_deeply $calls[12], ['z->`^.=`', ["\x00", undef]];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $z = $mock->z;
    my (undef) = - $z;
    my (undef) = ! $z;
    my (undef) = ~ $z;
    # my (undef) = ~. $z;

    my @calls = $mock->lazymock_calls;
    is @calls, 4;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`neg`', [undef, '']];
    is_deeply $calls[2], ['z->`!`', [undef, '']];
    is_deeply $calls[3], ['z->`~`', [undef, '']];
    # is_deeply $calls[4], ['z->`~.`', [undef, undef]];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $any_ref = $mock->get_ref;
    is $$any_ref, undef;
    is_deeply \@$any_ref, [];
    is $any_ref->(1, 2, 3), undef;
    is ref \*$any_ref, 'GLOB';
    is_deeply \%$any_ref, {};

    my @calls = $mock->lazymock_calls;
    is @calls, 6;
    is_deeply $calls[0], ['get_ref', []];
    is_deeply $calls[1], ['get_ref->`${}`', [undef, '']];
    is_deeply $calls[2], ['get_ref->`@{}`', [undef, '']];
    is_deeply $calls[3], ['get_ref->`&{}`', [undef, '']];
    is_deeply $calls[4], ['get_ref->`*{}`', [undef, '']];
    is_deeply $calls[5], ['get_ref->`%{}`', [undef, '']];
}

done_testing;
