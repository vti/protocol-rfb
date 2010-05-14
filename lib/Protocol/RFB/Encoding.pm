package Protocol::RFB::Encoding;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{buffer} = '';

    return $self;
}

1;
