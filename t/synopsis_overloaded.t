use strict;
use warnings;
use Test::AutoMock::Overloaded;
use Test::More import => [qw(is done_testing)];

my $mock = Test::AutoMock::Overloaded->new;

# define operators, hashes, arrays
$mock->automock_add_method('`+`' => 10);
$mock->automock_add_method('{key}' => 'value');
$mock->automock_add_method('[0]' => 'zero');

# call overloaded operators
is($mock + 5, 10);
is($mock->{key}, 'value');
is($mock->[0], 'zero');

# varify calls
$mock->automock_called_with_ok('`+`', [5, '']);
$mock->automock_called_ok('{key}');
$mock->automock_called_ok('[0]');

done_testing;
