package Protocol::RFB::Encoding::CopyRect;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub parse {
    my $self = shift;
    my $chunk = $_[0];

    return [unpack("nn", $chunk)];
}

1;
