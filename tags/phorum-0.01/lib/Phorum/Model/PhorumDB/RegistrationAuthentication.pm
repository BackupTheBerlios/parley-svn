package Phorum::Model::PhorumDB::RegistrationAuthentication;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->belongs_to(
    recipient => 'Phorum::Model::PhorumDB::Person',
);

=head1 NAME

Phorum::Model::PhorumDB::RegistrationAuthentication - Catalyst DBIC Table Model

=head1 SYNOPSIS

See L<Phorum>

=head1 DESCRIPTION

Catalyst DBIC Table Model.

=head1 AUTHOR

Chisel Wright,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
