package Test::LazyMock::Overloaded;
use strict;
use warnings;
use overload (
    '${}' => sub { _overload_nomethod(@_, '${}') },
    '@{}' => sub { _overload_nomethod(@_, '@{}') },
    '%{}' => sub { _overload_nomethod(@_, '%{}') },
    '&{}' => sub { _overload_nomethod(@_, '&{}') },
    '*{}' => sub { _overload_nomethod(@_, '*{}') },
    nomethod => \&_overload_nomethod,
    fallback => 0,
);
use parent qw(Test::LazyMock);

my %default_overload_handlers = (
    '+' => sub { $_[0] },
    '-' => sub { $_[0] },
    '*' => sub { $_[0] },
    '/' => sub { $_[0] },
    '%' => sub { $_[0] },
    '**' => sub { $_[0] },
    '<<' => sub { $_[0] },
    '>>' => sub { $_[0] },
    'x' => sub { $_[0] },
    '.' => sub { $_[0] },
    '+=' => sub { $_[0] },
    '-=' => sub { $_[0] },
    '*=' => sub { $_[0] },
    '/=' => sub { $_[0] },
    '%=' => sub { $_[0] },
    '**=' => sub { $_[0] },
    '<<=' => sub { $_[0] },
    '>>=' => sub { $_[0] },
    'x=' => sub { $_[0] },
    '.=' => sub { $_[0] },

    '<' => undef,
    '<=' => undef,
    '>' => undef,
    '>=' => undef,
    '==' => undef,
    '!=' => undef,

    '<=>' => undef,
    'cmp' => undef,

    'lt' => undef,
    'le' => undef,
    'gt' => undef,
    'ge' => undef,
    'eq' => undef,
    'ne' => undef,

    '&' => sub { $_[0] },
    '&=' => sub { $_[0] },
    '|' => sub { $_[0] },
    '|=' => sub { $_[0] },
    '^' => sub { $_[0] },
    '^=' => sub { $_[0] },
    # '&.' => sub { $_[0] },
    # '&.=' => sub { $_[0] },
    # '|.' => sub { $_[0] },
    # '|.=' => sub { $_[0] },
    # '^.' => sub { $_[0] },
    # '^.=' => sub { $_[0] },

    'neg' => sub { $_[0] },
    '!' => sub { $_[0] },
    '~' => sub { $_[0] },
    # '~.' => sub { $_[0] },

    '++' => sub { $_[0] },
    '--' => sub { $_[0] },

    'atan2' => undef,
    'cos' => undef,
    'sin' => undef,
    'exp' => undef,
    'abs' => undef,
    'log' => undef,
    'sqrt' => undef,
    'int' => undef,

    'bool' => sub { !! 1 },
    '""' => sub { "\x00" },
    '0+' => sub { 1 },
    'qr' => sub { qr/.*/ },

    '${}' => sub { \ my $x },
    '@{}' => sub { [] },
    '%{}' => sub { +{} },
    '&{}' => sub { sub {} },
    '*{}' => sub { \*DUMMY },
);

my $x = 0;
sub _overload_nomethod {
    my ($self, $other, $is_swapped, $operator, $is_numeric) = @_;

    # don't record the call of copy constructor (and don't copy mocks)
    return $self if $operator eq '=';

    my $operator_name = "`$operator`";
    $self->_call_method(
        $operator_name => [$other, $is_swapped],
        $default_overload_handlers{$operator},
    );
}

1;
__END__
