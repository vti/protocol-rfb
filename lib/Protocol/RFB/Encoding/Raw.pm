package Protocol::RFB::Encoding::Raw;

use strict;
use warnings;

use base 'Protocol::RFB::Encoding';

sub new {
    my $self = shift->SUPER::new(@_);

    die 'bits_per_pixel is required' unless $self->{bits_per_pixel};

    $self->{pixels} = [];

    return $self;
}

sub pixels { @_ > 1 ? $_[0]->{pixels} = $_[1] : $_[0]->{pixels} }

sub bits_per_pixel {
    @_ > 1 ? $_[0]->{bits_per_pixel} = $_[1] : $_[0]->{bits_per_pixel};
}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    $self->{buffer} .= $chunk;

    my $bpp = $self->bits_per_pixel;
    return -1 if length($self->{buffer}) % ($bpp / 8);

    for (my $i = 0; $i < length($self->{buffer}) / $bpp; $i++) {
        push @{$self->pixels},
          substr($self->{buffer}, $i, $bpp);
    }

    return 1;
}

1;
