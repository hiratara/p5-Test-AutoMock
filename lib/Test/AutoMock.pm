package Test::AutoMock;
use 5.008001;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(refaddr);
use Test::AutoMock::Mock;
use Test::AutoMock::Proxy::Functions qw(get_manager);

our $VERSION = "0.01";

our @EXPORT_OK = qw(mock mock_overloaded manager);

sub mock {
    my $mock = Test::AutoMock::Mock->new(@_);
    $mock->proxy;
}

sub mock_overloaded {
    my $mock = Test::AutoMock::Mock->new(
        @_,
        proxy_class => 'Test::AutoMock::Proxy::Overloaded',
    );
    $mock->proxy;
}

sub manager ($) {
    my $proxy = shift;
    get_manager $proxy;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock - A mock that can be used with a minimum setup

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

