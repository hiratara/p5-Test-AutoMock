package Test::AutoMock;
use 5.008001;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(refaddr);
use Test::AutoMock::Mock::Functions qw(new_mock get_manager);

our $VERSION = "0.01";

our @EXPORT_OK = qw(mock mock_overloaded manager);

sub mock { new_mock('Test::AutoMock::Mock::Basic', @_) }

sub mock_overloaded { new_mock('Test::AutoMock::Mock::Overloaded', @_) }

sub manager ($) {
    my $mock = shift;
    get_manager $mock;
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

