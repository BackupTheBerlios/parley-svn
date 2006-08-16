package Parley::Schema::Preference;

# Created by DBIx::Class::Schema::Loader v0.03004 @ 2006-08-10 09:12:24

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("preference");
__PACKAGE__->add_columns(
  "timezone",
  {
    data_type => "text",
    default_value => "'UTC'::text",
    is_nullable => 0,
    size => undef,
  },
  "preference_id",
  {
    data_type => "integer",
    default_value => "nextval('preference_preference_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("preference_id");
__PACKAGE__->has_many(
  "people",
  "Person",
  { "foreign.preference" => "self.preference_id" },
);

1;

