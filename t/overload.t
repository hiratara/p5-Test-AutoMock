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
    is_deeply $calls[1], ['z->+', [0, '']];
    is_deeply $calls[2], ['z->-', [0, '']];
    is_deeply $calls[3], ['z->*', [1, '']];
    is_deeply $calls[4], ['z->/', [1, '']];
    is_deeply $calls[5], ['z->%', [1, '']];
    is_deeply $calls[6], ['z->**', [1, '']];
    is_deeply $calls[7], ['z-><<', [0, '']];
    is_deeply $calls[8], ['z->>>', [0, '']];
    is_deeply $calls[9], ['z->x', [1, '']];
    is_deeply $calls[10], ['z->.', ['', '']];
}

{
    my $mock = Test::LazyMock::Overloaded->new;
    my $any_ref = $mock->get_ref;
    is $$any_ref, undef;
    is_deeply \@$any_ref, [];
    is $any_ref->(1, 2, 3), undef;
    is ref \*$any_ref, 'GLOB';
    # is_deeply \%$any_ref, {};

    my @calls = $mock->lazymock_calls;
    is @calls, 5;
    is_deeply $calls[0], ['get_ref', []];
    is_deeply $calls[1], ['get_ref->${}', [undef, '']];
    is_deeply $calls[2], ['get_ref->@{}', [undef, '']];
    is_deeply $calls[3], ['get_ref->&{}', [undef, '']];
    is_deeply $calls[4], ['get_ref->*{}', [undef, '']];
    # is_deeply $calls[], ['get_ref->%{}', [undef, undef]];
}

done_testing;
