package Parley::Controller::User::LostPassword;

use strict;
use warnings;
use base 'Catalyst::Controller';

use List::MoreUtils qw{ uniq };
use Digest::MD5 qw{ md5_hex };
use Readonly;
use Time::Piece;
use Time::Seconds;

# used by DFV
sub _dfv_constraint_confirm_equal {
    my $dfv  = shift;
    my $val1 = shift;
    my $val2 = shift;

    return ( $val1 eq $val2 );
}

sub _dfv_constraint_valid_email {
    my $dfv   = shift;
    my $email = shift;

    return Email::Valid->address($email);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Global class data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Readonly my $LIFETIME => Time::Seconds::ONE_HOUR;

my %dfv_profile_for = (
    'password_reset' => {
        require_some => {
            user_details => [
                1,
                qw/ username email /
            ],
        },

        filters => [qw(trim)],

        constraint_methods => {
            email => {
                name => 'email',
                constraint_method => \&_dfv_constraint_valid_email,
                params      => [qw( email )],
            },
        },

        msgs => {
            constraints => {
                email => q{You must enter a valid email address},
            },
            missing => q{One or more required fields are missing},
            format => '%s',
        },
    },

    'set_new_password' => {
        required => [
            qw/
                reset_username
                new_password
                confirm_password
            /
        ],

        filters => [qw(trim)],

        constraint_methods => {
            confirm_password => {
                name => 'confirm_password',
                constraint  => \&_dfv_constraint_confirm_equal,
                params      => [qw( new_password confirm_password )],
            },
        },

        msgs => {
            constraints => {
                confirm_password => q{The passwords do not match},
            },
            missing => q{One or more required fields are missing},
            format => '%s',
        },
    }
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller Actions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# nice and easy - catch the url to display the lost password page
# if we have a form submit, deal with it
sub lost_password : Path('/user/password/forgotten') {
    my ($self, $c) = @_;
    my ($results, @messages);

    if (defined $c->request->method()
            and $c->request->method() eq 'POST'
            and defined $c->request->param('pwd_reset_submit')
    ) {
        @messages = $self->_user_reset($c);

        # if we have any validation errors ...
        if (scalar @messages) {
            $c->stash->{messages} = \@messages;
        }

        # no messages, means that all should be well, so head off to the
        # "details in the post" page
        else {
            $c->stash->{template} = 'user/lostpassword/lost_password_details_sent';
        }
    }
}


# this action uses the uid in the URL to work out who's password we are
# resetting, after a little validation, we can use the new choice of password
# for the user
sub reset : Path('/user/password/reset') {
    my ($self, $c, $reset_uid) = @_;
    my ($results, @messages);


    # we should have the reset UID in the URL
    if (not defined $reset_uid) {
        $c->stash->{error}{message} = q{Incomplete password reset URL};
        return;
    }

    # fetch the info from the database
    my $pwd_reset = $c->model('ParleyDB')->resultset('PasswordReset')->find(
        {
            password_reset_id => $reset_uid,
        }
    );

    # if we don't have any matches then the id was bogus
    if (not defined $pwd_reset) {
        $c->stash->{error}{message} = q{Bogus password reset ID};
        return;
    }

    # put the reset_uid into the stash
    $c->stash->{reset_uid} = $reset_uid;

    # make user available to template
    $c->stash->{reset_user} = $pwd_reset->recipient();

    # deal with a form submission
    if (defined $c->request->method()
            and $c->request->method() eq 'POST'
            and defined $c->request->param('reset_password')
    ) {
        @messages = $self->_reset_password($c, $pwd_reset);

        # if we have any validation errors ...
        if (scalar @messages) {
            $c->stash->{messages} = \@messages;
        }

        # no messages, means that all should be well, so head off to the
        # "details in the post" page
        else {
            $c->stash->{template} = 'user/lostpassword/reset_success';
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller (Private/Helper) Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _reset_password {
    my ($self, $c, $pwd_reset) = @_;
    my (@messages);

    # validate form data
    $c->form(
        $dfv_profile_for{set_new_password}
    );

    # deal with missing/invalid fields
    if ($c->form->has_missing()) {
        $c->stash->{view}{error}{message} = q{You must fill in all the required fields};
        foreach my $f ( $c->form->missing ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
    }
    elsif ($c->form->has_invalid()) {
        $c->stash->{view}{error}{message} = q{One or more fields are invalid};
        foreach my $f ( $c->form->invalid ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
    }

    # otherwise the form data is ok...
    else {
        # less typing ..
        my $reset_username = $pwd_reset->recipient()->authentication()->username;

        # make sure the username matches
        if ($reset_username eq $c->form->valid->{reset_username}) {
            # perform everything in a transaction
            eval {
                $c->model('ParleyDB')->schema->txn_do(
                    sub { return $self->_txn_user_password_update($c, $pwd_reset); }
                );
            };
            # deal with any transaction errors
            if ($@) {                                   # Transaction failed
                die "something terrible has happened!"  #
                    if ($@ =~ /Rollback failed/);       # Rollback failed

                $c->stash->{error}{message} = qq{Database transaction failed: $@};
                $c->log->error( $@ );
                return;
            }
        }
        else {
            # incorrect username
            push @messages, 'Incorrect username supplied';
        }
    }

    return uniq(sort @messages);
}

sub _send_username_reminder {
    my ($self, $c, $person) = @_;
    my ($send_status);
    
    # send the email
    $send_status = $c->send_email(
        {
            template    => q{username_reminder.eml},
            person      => $person,
            headers => {
                from    => $c->application_email_address(),
                subject => qq{Your @{[$c->config->{name}]} username},
            },
        }
    );
}

sub _user_password_reset {
    my ($self, $c, $person) = @_;
    my ($pwd_reset, $send_status);

    # make the update in a transaction
    eval {
        $pwd_reset = $c->model('ParleyDB')->schema->txn_do(
            sub { return $self->_txn_password_reset($c, $person) }
        );
    };
    # deal with any transaction errors
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        $c->stash->{error}{message} = qq{Database transaction failed: $@};
        $c->log->error( $@ );
        return;
    }

    # getting here means that we've created a new password_reset entry,
    # zapped the current password, and set authenticated=f for the person

    # now send the user an email
    # send an email off to the (new) user
    $send_status = $c->send_email(
        {
            template    => q{password_reset.eml},
            person      => $person,
            headers => {
                from    => $c->application_email_address(),
                subject => qq{Reset your @{[$c->config->{name}]} password},
            },
            template_data => {
                pwd_reset => $pwd_reset,
            },
        }
    );

    return $send_status;
}

sub _user_reset {
    my ($self, $c) = @_;
    my ($results, @messages, $email_send_status, $send_username_reminder);

    # validate the form data
    $c->form(
        $dfv_profile_for{password_reset}
    );

    # deal with missing/invalid fields
    if ($c->form->has_missing()) {
        $c->stash->{view}{error}{message} = q{You must fill in all the required fields};
        foreach my $f ( $c->form->missing ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
    }
    elsif ($c->form->has_invalid()) {
        $c->stash->{view}{error}{message} = q{One or more fields are invalid};
        foreach my $f ( $c->form->invalid ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
    }

    # otherwise the form data is ok...
    else {
        my ($criteria, $matches, $person);

        # make sure we can match user/email supplied
        if (defined $c->form->valid->{username}) {
            $criteria->{'authentication.username'}
                = $c->form->valid->{username};

            # make sure we don't send a username reminder
            $send_username_reminder = 0;
        }
        elsif (defined $c->form->valid->{email}) {
            $criteria->{'email'}
                = $c->form->valid->{email};

            # assume the user used their email address because they couldn't
            # remember their username, and send them a username reminder email
            $send_username_reminder = 1;
        }
        else {
            push @messages, q{Missing criteria in the database lookup};
            $c->log->error(q{Lookup criteria missing in _user_reset()});
            return uniq(sort @messages);
        }
        $matches = $c->model('ParleyDB')->resultset('Person')->search(
            $criteria,
            {
                join => 'authentication',
            }
        );

        # make sure we don't have too many matches
        if ($matches->count > 1) {
            push @messages, q{Database lookup returned too many records};
            $c->log->error(q{Looks like the SQL for password reset is a bit borked});
            $c->log->error(
                  q{Lookup returned }
                . $matches->count
                . q{ record(s)}
            );
            $c->log->dumper($criteria);
            return uniq(sort @messages);
        }

        # make sure we don't have too few matches
        elsif ($matches->count < 1) {
            push @messages, q{There are no users matching that information};
            $c->log->debug(' NO MATCHES ');
        }

        # otherwise, do the work
        else {
            # get the first (and should be only) match
            $person = $matches->first();
            $c->log->dumper( $person->{_column_data}, 'COLUMN_DATA' );

            # if required, send a username reminder
            if ($send_username_reminder) {
                $self->_send_username_reminder($c, $person);
            }

            # do the actual password reset
            $email_send_status = $self->_user_password_reset($c, $person);
            if (not $email_send_status) {
                push @messages, q{Failed to send password reset email};
            }
        }
    }

    return uniq(sort @messages);
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions for database transactions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _txn_password_reset {
    my ($self, $c, $person) = @_;
    my ($random, $pwd_reset);

    $c->log->dumper( ref $self,     'REF_SELF' );
    $c->log->dumper( ref $c,        'REF_C' );
    $c->log->dumper( ref $person,   'REF_PERSON' );

    # if it's good enough for Cozens, it's good enough for me :-)
    $random = md5_hex(time.(0+{}).$$.rand);

    # create an invitation
    $pwd_reset = $c->model('ParleyDB')->resultset('PasswordReset')->create(
        {
            'password_reset_id' => $random,
            'recipient'		=> $person->person_id,
            'expires'		=> Time::Piece->new(time + $LIFETIME)->datetime,
        }
    );

    # as far as I know, no md5_hex value is 'X', so set the hexed password to X
    # to prevent anyone logging in after a reset request
    $person->authentication->password('X');
    # the person is no longer authenticated
    $person->authentication->authenticated(0);
    # update the person's record
    $person->authentication->update();

    # return the new entry in password_reset so it ca be used back up the
    # chain, e.g. in the email to the user
    return $pwd_reset;
}

sub _txn_user_password_update {
    my ($self, $c, $pwd_reset) = @_;

    # less typing
    my $authentication = $pwd_reset->recipient()->authentication();

    # update the user's password
    $authentication->password(
        md5_hex( $c->form->valid->{new_password} )
    );

    # set the user as authenticated
    $authentication->authenticated( 1 );

    # update authentication information
    $authentication->update();

    # delete all outstanding reset URLs for the user
    $c->model('ParleyDB')->resultset('PasswordReset')->search(
        {
            recipient => $pwd_reset->recipient()->id()
        }
    ) ->delete;
}

1;
__END__

=pod

=head1 NAME

Parley::Controller::User::LostPassword

=cut

vim: ts=8 sts=4 et sw=4 sr sta
