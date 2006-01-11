package Forum::Model::ForumDB::RegistrationAuthentication;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->belongs_to(
    recipient => 'Forum::Model::ForumDB::Person',
);

=head1 NAME

Forum::Model::ForumDB::RegistrationAuthentication - Catalyst DBIC Table Model

=head1 SYNOPSIS

See L<Forum>

=head1 DESCRIPTION

Catalyst DBIC Table Model.

=head1 AUTHOR

Chisel Wright,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
