package Parley::Schema::Post;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;
use Data::Dump qw(pp);

use DateTime;
use DateTime::Format::Pg;
use Text::Context::EitherSide;
use Text::Search::SQL;

use Parley::App::DateTime qw( :interval );

use base 'DBIx::Class';

__PACKAGE__->load_components("ResultSetManager", "PK::Auto", "Core");
__PACKAGE__->table("post");
__PACKAGE__->add_columns(
  "creator",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "subject",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "quoted_post",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "message",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "quoted_text",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "created",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "thread",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "reply_to",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "post_id",
  {
    data_type => "integer",
    default_value => "nextval('post_post_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "edited",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },

  ip_addr => {
    data_type => "inet",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("post_id");
__PACKAGE__->has_many("threads", "Thread", { "foreign.last_post" => "self.post_id" });
__PACKAGE__->has_many("forums", "Forum", { "foreign.last_post" => "self.post_id" });
__PACKAGE__->belongs_to("creator", "Person", { person_id => "creator" });
__PACKAGE__->belongs_to("reply_to", "Post", { post_id => "reply_to" });
__PACKAGE__->has_many(
  "post_reply_toes",
  "Post",
  { "foreign.reply_to" => "self.post_id" },
);
__PACKAGE__->belongs_to("thread", "Thread", { thread_id => "thread" });
__PACKAGE__->belongs_to("quoted_post", "Post", { post_id => "quoted_post" });
__PACKAGE__->has_many(
  "post_quoted_posts",
  "Post",
  { "foreign.quoted_post" => "self.post_id" },
);
__PACKAGE__->has_many("people", "Person", { "foreign.last_post" => "self.post_id" });




foreach my $datecol (qw/created edited/) {
    __PACKAGE__->inflate_column($datecol, {
        inflate => sub { DateTime::Format::Pg->parse_datetime(shift); },
        deflate => sub { DateTime::Format::Pg->format_datetime(shift); },
    });
}



# we used to use ->slice() but it sopped working on page #2 (!!)
# this may be slower [not benchmarked] but it works
sub last_post_in_list : ResultSet {
    my ($self, $post_list) = @_;
    my ($current_post);

    while (my $tmp = $post_list->next()) {
        # do nothing, we're just iterating the list
        $current_post = $tmp;
        #warn qq{LOOP: } . ref($current_post);
    }
    # return the current post, which is the last one we saw
    # i.e. the last one in the list
    #warn qq{CURRENT: } . ref($current_post);
    return $current_post;
}


sub next_post :ResultSet {
    my ($self, $post) = @_;
    my $next_post;

    # we want to find the next post after the one we've been given, based on
    # creation time
    # if for some reason there are no matches, just return the post we were passed
    $next_post = $self->search(
        {
            created => { '>' => DateTime::Format::Pg->format_datetime($post->created()) },
            thread  => $post->thread()->id(),
        },
        {
            rows    => 1,
        }
    );

    if (defined $next_post->first()) {
        return $next_post->first();
    }

    return $post;
}


sub page_containing_post : ResultSet {
    my ($self, $post, $posts_per_page) = @_;

    my $position_in_thread = $self->thread_position($post);

    # work out what page the Nth post is on
    my $page_number = int(($position_in_thread - 1) / $posts_per_page) + 1;

    return $page_number;
}


sub thread_position : ResultSet {
    my ($self, $post) = @_;

    if (not defined $post) {
        warn('$post id undefined in call to Parley::Model::ParleyDB::Post->thread_position()');
        return;
    }

    # explicitly 'deflate' the creation time, as DBIx::Class (<=v0.06003) doesn't deflate on search()
    my $position = $self->count(
        {
            thread  => $post->thread()->id(),
            created => {
                '<='   => DateTime::Format::Pg->format_datetime($post->created())
            },
        }
    );

    return $position;
}

# accessor to use in search results to return context matches
sub match_context {
    my $self = shift;
    my $search_terms = shift;
    my ($tss, $terms);

    if (not defined $search_terms) {
        return;
    }

    $tss = Text::Search::SQL->new(
        {
            search_term     => $search_terms,
        }
    );
    $tss->parse();
    $terms = $tss->get_chunks();
    warn pp($terms);
    warn pp($self->message());

    my $context = Text::Context::EitherSide->new( $self->message(), context => 3 );
    return $context->as_string( @{ $terms } );
}

sub interval_ago {
    my $self = shift;
    my ($now, $duration, $longest_duration);

    my $interval_string = interval_ago_string(
        $self->created()
    );
    return $interval_string;
}

1;
__END__
vim: ts=8 sts=4 et sw=4 sr sta

