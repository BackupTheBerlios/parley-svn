package Forum::Model::ForumDB::Person;

use strict;
use warnings;
use base 'DBIx::Class::Core';

#__PACKAGE__->add_columns(qw/person_id first_name last_name email forum_name authentication/);
#__PACKAGE__->set_primary_key('person_id');

__PACKAGE__->belongs_to(
    authentication => 'Forum::Model::ForumDB::Authentication'
);

=head1 NAME

Forum::Model::ForumDB::Person - Catalyst DBIC Table Model

=head1 SYNOPSIS

See L<Forum>

=head1 DESCRIPTION

Catalyst DBIC Table Model.

=head1 AUTHOR

Chisel Wright C<< <pause@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
