package Forum::View::TT;

use strict;
use base 'Catalyst::View::TT';

# allow us to configure TT from the application config
__PACKAGE__->config( Forum->config->{template} );

=head1 NAME

Forum::View::TT - Catalyst TT View

=head1 SYNOPSIS

See L<Forum>

=head1 DESCRIPTION

Catalyst TT View.

=head1 AUTHOR

Chisel Wright,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
