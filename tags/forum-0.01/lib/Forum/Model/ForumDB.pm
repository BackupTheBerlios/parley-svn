package Forum::Model::ForumDB;
use strict;

use base 'Catalyst::Model::DBIC';

__PACKAGE__->config(
    dsn           => 'dbi:Pg:dbname=forum',
    user          => 'forum',
    password      => '',
    options       => {
        AutoCommit => 1,
    },
    relationships => 1,
);

=head1 NAME

Forum::Model::ForumDB - Catalyst DBIC Model

=head1 SYNOPSIS

See L<Forum>

=head1 DESCRIPTION

Catalyst DBIC Model.

=head1 AUTHOR

Chisel Wright C<< <pause@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
