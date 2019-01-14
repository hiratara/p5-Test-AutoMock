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

    '${}' => sub { \ my $x },
    '@{}' => sub { [] },
    '%{}' => sub { +{} },
    '&{}' => sub { sub {} },
    '*{}' => sub { \*DUMMY },
);

my $x = 0;
sub _overload_nomethod {
    my ($self, $other, $is_swapped, $operator, $is_numeric) = @_;
    my $operator_name = "`$operator`";

    $self->_call_method(
        $operator_name => [$other, $is_swapped],
        $default_overload_handlers{$operator},
    );
}

1;
__END__
