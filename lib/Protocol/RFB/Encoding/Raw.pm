package Protocol::RFB::Encoding::Raw;

use strict;
use warnings;

my $IS_BIG_ENDIAN = unpack('h*', pack('s', 1)) =~ /01/ ? 1 : 0;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    die 'pixel_format is required' unless $self->{pixel_format};

    return $self;
}

sub parse {
    my $self = shift;
    my $chunk = $_[0];

    my $pixel_format = $self->{pixel_format};

    my $bpp = $pixel_format->bits_per_pixel;

    my $unpack =
        ($pixel_format->big_endian_flag && !$IS_BIG_ENDIAN)
      ? $bpp == 32
          ? 'N'
          : $bpp == 16 ? 'n'
        : 'C'
      : $bpp == 32 ? 'L'
      : $bpp == 16 ? 'S'
      :              'C';

    my @pixels = unpack("$unpack*", $chunk);

    my $red_shift = $pixel_format->red_shift;
    my $red_max   = $pixel_format->red_max;

    my $green_shift = $pixel_format->green_shift;
    my $green_max   = $pixel_format->green_max;

    my $blue_shift = $pixel_format->blue_shift;
    my $blue_max   = $pixel_format->blue_max;

    my $parsed = [];
    foreach my $pixel (@pixels) {
        my $red   = ($pixel >> $red_shift) & $red_max;
        my $green = ($pixel >> $green_shift) & $green_max;
        my $blue  = ($pixel >> $blue_shift) & $blue_max;

        push @$parsed, [$red, $green, $blue];
    }

    return $parsed;
}

1;
