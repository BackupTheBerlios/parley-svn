package Phorum::Model::PhorumDB;
use strict;

use base 'Catalyst::Model::DBIC';

__PACKAGE__->config(
    dsn           => 'dbi:Pg:dbname=phorum',
    user          => 'phorum',
    password      => undef,
    options       => {
        AutoCommit => 1,
    },
    relationships => 1,
);

=head1 NAME

Phorum::Model::PhorumDB - Catalyst DBIC Model

=head1 SYNOPSIS

See L<Phorum>

=head1 DESCRIPTION

Catalyst DBIC Model.

=head1 AUTHOR

Chisel Wright C<< <pause@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
