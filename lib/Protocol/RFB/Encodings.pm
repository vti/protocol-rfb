package Protocol::RFB::Encodings;

use strict;
use warnings;

our $ENCODINGS = {
    'Raw'         => 0,
    'CopyRect'    => 1,
    'RRE'         => 2,
    'Hextile'     => 5,
    'ZRLE'        => 16,
    'Cursor'      => -239,
    'DesktopSize' => -223
};

sub encoding {
    my $q = $_[1];

    return unless defined $q;

    if ($q =~ m/^\d+$/) {
        foreach my $key (keys %$ENCODINGS) {
            return $key if $ENCODINGS->{$key} == $q;
        }

        return;
    }

    return $ENCODINGS->{$q}
}

1;
