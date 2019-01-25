package Test::LazyMock::Overloaded;
use strict;
use warnings;
use overload (
    '${}' => sub { _overload_nomethod(@_, '${}') },
    '@{}' => \&_deref_array,
    '%{}' => \&_deref_hash,
    '&{}' => \&_deref_code,
    '*{}' => sub { _overload_nomethod(@_, '*{}') },
    nomethod => \&_overload_nomethod,
    fallback => 0,
);
use parent qw(Test::LazyMock);
use Test::LazyMock::Overloaded::TieArray;
use Test::LazyMock::Overloaded::TieHash;

my %default_overload_handlers = (
    '+' => undef,
    '-' => undef,
    '*' => undef,
    '/' => undef,
    '%' => undef,
    '**' => undef,
    '<<' => undef,
    '>>' => undef,
    'x' => undef,
    '.' => undef,

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

    '&' => undef,
    '&=' => sub { $_[0] },
    '|' => undef,
    '|=' => sub { $_[0] },
    '^' => undef,
    '^=' => sub { $_[0] },
    # '&.' => undef,
    # '&.=' => sub { $_[0] },
    # '|.' => undef,
    # '|.=' => sub { $_[0] },
    # '^.' => undef,
    # '^.=' => sub { $_[0] },

    'neg' => undef,
    '!' => undef,
    '~' => undef,
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
    '""' => sub {
        my $self = shift;
        $self->_exec_without_overloads(sub { "$self" });
    },
    '0+' => sub { 1 },
    'qr' => sub { qr// },

    '<>' => sub { undef },

    '-X' => undef,

    # '~~' => sub { !! 1 },

    '${}' => sub { \ my $x },
    '*{}' => sub { \*DUMMY },
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $self_fields = $self->_get_fields;

    $self_fields->{_lazymock_tie_hash} = do {
        tie my %h, 'Test::LazyMock::Overloaded::TieHash', $self;
        \%h;
    };
    $self_fields->{_lazymock_tie_array} = do {
        tie my @arr, 'Test::LazyMock::Overloaded::TieArray', $self;
        \@arr;
    };

    $self;
}

my $x = 0;
sub _overload_nomethod {
    my ($self, $other, $is_swapped, $operator, $is_numeric) = @_;

    # don't record the call of copy constructor (and don't copy mocks)
    return $self if $operator eq '=';

    my $operator_name = "`$operator`";
    my $default_handler;
    if (exists $default_overload_handlers{$operator}) {
        $default_handler = $default_overload_handlers{$operator};
    } else {
        warn "unknown operator: $operator";
    }

    $self->_call_method(
        $operator_name => [$other, $is_swapped],
        $default_overload_handlers{$operator},
    );
}

sub _deref_hash {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    # don't record `%{}` calls

    $self_fields->{_lazymock_tie_hash}
}

sub _deref_array {
    my $self = shift;
    my $self_fields = $self->_get_fields;

    # don't record `@{}` calls

    $self_fields->{_lazymock_tie_array};
}

sub _deref_code {
    my $self = shift;

    # don't record `&{}` calls

    sub {
        my @args = @_;
        $self->_call_method('()', [@_], undef);
    };
}

1;
__END__