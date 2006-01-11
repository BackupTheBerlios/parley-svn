package Phorum::Controller::Thread;

use strict;
use warnings;
use base 'Catalyst::Controller';

use List::MoreUtils qw{ uniq };

use Phorum::App::Helper;
use Data::FormValidator 4.02;

our $DFV;

BEGIN {
    $DFV = Data::FormValidator->new(
        {
            'new_topic' => {
                required        => [qw/thread_subject thread_message/],
                field_filters   => {
                    thread_subject  => 'trim',
                    thread_message  => 'trim',
                },
                msgs => {
                    missing => q{One or more required fields are missing},
                    format => '%s',
                },
            },
            'new_reply' => {
                required        => [qw/thread_message/],
                optional        => [qw/thread_subject/],
                field_filters   => {
                    thread_subject  => 'trim',
                    thread_message  => 'trim',
                },
                msgs => {
                    missing => q{One or more required fields are missing},
                    format => '%s',
                },
            },
        }
    );
}

sub view : Local {
    my ($self, $c) = @_;

    $c->stash->{post_list} = $c->model('PhorumDB')->table('post')->search(
        {
            thread => $c->stash->{current_thread}->id(),
        },
        {
        }
    );
}

sub add : Local {
    my ($self, $c) = @_;

    # need to be logged in to post
    $self->_login_if_required($c, q{You must be logged in before you can start a new topic.});

    # need to be authenticated to post
    if (not Phorum::App::Helper->is_authenticted($c)) {
        $c->stash->{error}{message} = q{You need to authenticate your registration before you can start a new topic.};
    }
}

sub reply : Local {
    my ($self, $c) = @_;

    # need to be logged in to post
    $self->_login_if_required($c, q{You must be logged in before you can add a reply.});

    # need to be authenticated to post
    if (not Phorum::App::Helper->is_authenticted($c)) {
        $c->stash->{error}{message} = q{You need to authenticate your registration before you can reply to a topic.};
    }
}

sub post : Local {
    my ($self, $c) = @_;
    my (@messages);

    # assume success, deal with failure later
    $c->stash->{template} = 'thread/view';

    if ($c->request->param('post_topic')) {
        @messages = $self->_add_new_topic($c);
    }
    elsif ($c->request->param('post_reply')) {
        @messages = $self->_add_new_reply($c);
    }
    elsif ($c->request->param('cancel_new_topic')) {
        $c->response->redirect( $c->request->base() . 'forum/view?forum=' . $c->stash->{current_forum}->id());
    }

    if (scalar @messages) {
        $c->log->error('FillInForm needed');
        # show the appropriate template
        if ($c->request->param('post_topic')) {
            $c->stash->{template} = 'thread/add';
        }
        elsif ($c->request->param('post_reply')) {
            $c->stash->{template} = 'thread/reply';
        }
        $c->stash->{messages} = \@messages;
    }
}

sub _login_if_required {
    my ($self, $c, $message) = @_;

    if( not Phorum::App::Helper->is_logged_in($c) ) {
        # make sure we return here after a successful login
        $c->session->{after_login} = $c->request->uri();
        # set an informative message to display on the login screen
        if (defined $message) {
            $c->session->{login_message} = $message;
        }
        # send the user to the login screen
        $c->response->redirect( $c->req->base() . 'user/login' );
    }
}

sub _add_new_topic {
    my ($self, $c) = @_;
    my ($results, @messages);

    if ($DFV) {
        $results = $DFV->check($c->request->parameters, 'new_topic');
    };

    if ($results || !$DFV) {
        # create a new thread
        my $new_thread = $c->model('PhorumDB')->table('thread')->create(
            {
                forum       => $c->stash->{current_forum}->id(),
                subject     => $results->valid->{thread_subject},
                creator     => $c->session->{authed_user}->id(),
            }
        );

        # create a new post in the new thread
        my $new_post = $c->model('PhorumDB')->table('post')->create(
            {
                thread      => $new_thread->id(),
                subject     => $results->valid->{thread_subject},
                message     => $results->valid->{thread_message},
                creator     => $c->session->{authed_user}->id(),
            }
        );

        # view the new thread
        $c->response->redirect( $c->req->base . 'thread/view?thread=' . $new_thread->id() );
    }
    else {
        $c->log->error('DFV failed');
        push @messages, map {$_} values %{$results->msgs};
    }

    return (uniq(sort @messages));
}

sub _add_new_reply {
    my ($self, $c) = @_;
    my ($results, @messages);

    if ($DFV) {
        $results = $DFV->check($c->req->parameters, 'new_reply');
    };

    if ($results || !$DFV) {
        # create a new reply to a thread
        my $new_post = $c->model('PhorumDB')->table('post')->create(
            {
                thread      => $c->stash->{current_thread}->id(),
                subject     => ($results->valid->{thread_subject} || undef),
                message     => $results->valid->{thread_message},
                creator     => $c->session->{authed_user}->id(),
            }
        );

        # view the new thread
        $c->response->redirect( $c->req->base . 'thread/view?thread=' . $c->stash->{current_thread}->id() );
    }
    else {
        $c->log->error('DFV failed');
        push @messages, map {$_} values %{$results->msgs};
    }

    return (uniq(sort @messages));
}


=head1 NAME

Phorum::Controller::Thread - Catalyst Controller

=head1 SYNOPSIS

See L<Phorum>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head1 AUTHOR

Chisel Wright C<< <pause@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
