package Phorum::Controller::Forum;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Phorum::Controller::Phorum - Catalyst Controller

=head1 SYNOPSIS

See L<Phorum>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body('Phorum::Controller::Phorum is on Catalyst!');
}

sub list : Local {
    my ($self, $c) = @_;
    #$c->response->body('forum list');

    $c->stash->{forum_list} = $c->model('PhorumDB')->table('forum')->search(
        {
            active => 1,
        },
        {
        }
    );
}

sub view : Local {
    my ($self, $c) = @_;

    $c->stash->{thread_list} = $c->model('PhorumDB')->table('thread')->search(
        {
            forum   => $c->stash->{current_forum}->id(),
        },
        {
        }
    );
}

=head1 AUTHOR

Chisel Wright C<< <pause@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
