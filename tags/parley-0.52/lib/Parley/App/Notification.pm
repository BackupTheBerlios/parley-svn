package Parley::App::Notification;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Perl6::Export::Attrs;

sub notify_watchers :Export( :watch ) {
    my ($c, $post) = @_;
    my ($send_status);

    # get a list of people we want to inform
    my $notification_list = $c->model('ParleyDB')->resultset('ThreadView')
        ->notification_list( $post )
    ;
    $c->log->debug( q{No. WATCHERS: } . $notification_list->count() );

    # loop through the list [resultset], queue and email
    # and update the time they were last notified
    while (my $thread_view_row = $notification_list->next()) {
        $c->log->debug( q{NOTIFY: } . $thread_view_row->person()->id() );
        $c->log->debug( q{NOTIFY: } . $thread_view_row->person()->forum_name() );

        # send email
        $send_status = $c->send_email(
            {
                template        => {
                    text    => q{thread_update_notify.eml},
                    html    => q{thread_update_notify.html},
                },
                person          => $thread_view_row->person(),
                headers         => {
                    from    => $c->application_email_address(),
                    subject => qq{New Reply: } . $post->thread()->subject(),
                },
                template_data   => {
                    post    => $post,
                },
            }
        );

        # update thread_view record for thread-person
        my $thread_view_record = $c->model('ParleyDB')->resultset('ThreadView')
            ->find(
                person  => $thread_view_row->person()->id(),
                thread  => $post->thread()->id(),
            )
        ;
        $thread_view_record->last_notified(
            #$thread_view_record->timestamp()
            Time::Piece->new(time)->datetime,
        );
        $thread_view_record->update();
    }

    return;
}


1;

__END__

=head1 NAME

Parley::App::Notification - notification helper functions

=head1 SYNOPSIS

  use Parley::App::Notification;

  $c->notify_watchers($post);

=head1 SEE ALSO

L<Parley::Controller::Root>, L<Catalyst::Plugin::Email>, L<Catalyst>

=head1 AUTHOR

Chisel Wright C<< <chisel@herlpacker.co.uk> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
