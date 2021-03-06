package Parley;

use strict;
use warnings;

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
# Static::Simple: will serve static files from the applications root directory
#
use Catalyst qw/
    -Debug
    Dumper
    StackTrace

    ConfigLoader

    Email
    Static::Simple

    Session
    Session::Store::FastMmap
    Session::State::Cookie

    Authentication
    Authentication::Store::DBIC
    Authentication::Credential::Password

    Prototype
    FillInForm
    DefaultEnd
/;

use Parley::App::Helper;
use YAML;

our $VERSION = '0.10-pre';

#
# Configure the application
#
__PACKAGE__->config( version => $VERSION );
__PACKAGE__->setup;

# only show certain log levels in output
__PACKAGE__->log (Catalyst::Log->new( @{__PACKAGE__->config->{log_levels}} ));


# a function that easily lets us refer to where we're storing authed user
# information - we had to change it from session to stash with a DBIx::Class
# upgrade
sub authed_user {
    my ($c, $value) = @_;

    if (defined $value) {
        $c->stash->{authed_user} = $value;
    }

    return $c->stash->{authed_user};
}

sub auto : Private {
    my ($self, $c) = @_;

    # warn people about the DBIx::Class::Loader issue
    my $dcl_version = DBIx::Class::Loader->VERSION;
    if ($dcl_version =~ m{\A0.1[012]\z}) {
        $c->stash->{error}{message} = qq{
            <p>You are using a version of DBIx::Class::Loader (v$dcl_version)
                that is known to not work with this application.</p>
            <p>This issue has been resolved.</p>
            <p>Please upgrade to v0.13 or higher</p>
        };
        return;
    }

    # if we have a user ... fetch some info (if we don't already have it)
    if ( $c->user and not defined $c->authed_user ) {
        $c->log->info('Fetching user information for ' . $c->user->id);

        # get the person info for the username
        my $results = $c->model('ParleyDB')->table('person')->search(
            {
                'authentication.username'   => $c->user->username(),
            },
            {
                join => 'authentication',
            },
        );
        $c->authed_user( $results->first() );

        #####################################################################
        # cater for database upgrades, and make sure the user has preferences
        #####################################################################
        Parley::App::Helper->user_preference_check($c);
    }


    # do we have a post id in the URL?
    if (defined $c->req->param('post')) {
        if (not $c->req->param('post') =~ m{\A\d+\z}) {
            $c->stash->{error}{message} = 'non-integer post id passed: ['
                . $c->req->param('post')
                . ']';
            return;
        }
        #$c->log->debug('[from post #] setting: current_post');
        $c->stash->{current_post} = $c->model('ParleyDB')->table('post')->search(
            post_id  => $c->req->param('post'),
        )->first;

        # set the current_thread from the current_post
        #$c->log->debug('[from post #] setting: current_thread');
        $c->stash->{current_thread} = $c->stash->{current_post}->thread();

        # set the current_forum from the current thread
        #$c->log->debug('[from post #] setting: current_forum');
        $c->stash->{current_forum} = $c->stash->{current_thread}->forum();
    }

    # do we have a thread id in the URL?
    elsif (defined $c->req->param('thread')) {
        $c->log->debug(qq{thread value is } . $c->request->param('thread'));
        if (not $c->req->param('thread') =~ m{\A\d+\z}) {
            $c->stash->{error}{message} = 'non-integer thread id passed: ['
                . $c->req->param('thread')
                . ']';
            return;
        }
        #$c->log->debug('[from thread #] setting: current_thread');
        $c->stash->{current_thread} = $c->model('ParleyDB')->table('thread')->search(
            thread_id  => $c->req->param('thread'),
        )->first;

        # set the current_forum from the current thread
        #$c->log->debug('[from thread #] setting: current_forum');
        $c->stash->{current_forum} = $c->stash->{current_thread}->forum();
    }

    # do we have a forum id in the URL?
    elsif (defined $c->req->param('forum')) {
        $c->log->debug(qq{forum value is } . $c->request->param('forum'));
        if (not $c->req->param('forum') =~ m{\A\d+\z}) {
            $c->stash->{error}{message} = 'non-integer forum id passed: ['
                . $c->req->param('forum')
                . ']';
            return;
        }
        #$c->log->debug('[from forum #] setting: current_forum');

        $c->stash->{current_forum} = $c->model('ParleyDB')->table('forum')->search(
            forum_id  => $c->req->param('forum'),
        )->first;
    }

    return 1;
}


#
# Output a friendly welcome message
#
sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->status(404);
    $c->response->body( '404 Not Found' );
}

sub index : Private {
    my ( $self, $c ) = @_;
    # redirect to the default action
    $c->response->redirect( $c->uri_for($c->config->{default_uri}) );
}

# updated to use information from: http://catalyst.perl.org/calendar/2005/8/
sub end : Private {
    my ($self, $c) = @_;

    # if we have any error(s) in the stash, automatically show the error page
    if (defined $c->stash->{error}) {
        $c->stash->{template} = 'error/simple';
    }

    # use DefaultEnd magic
    $self->NEXT::end( $c );

    # (re)populate the form
    $c->fillform( $c->stash->{formdata} );
}



=head1 NAME

Parley - Catalyst based application

=head1 SYNOPSIS

    script/forum_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 METHODS

=head2 auto

=head1 AUTHOR

Chisel Wright C<< <pause@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
