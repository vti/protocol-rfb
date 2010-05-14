package Protocol::RFB::Message::FramebufferUpdate;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use Protocol::RFB::Encodings;
use Protocol::RFB::Encoding::Raw;

sub new {
    my $self = shift->SUPER::new(@_);

    die 'pixel_format is required' unless $self->{pixel_format};

    $self->{rectangles} ||= [];

    return $self;
}

sub name { 'framebuffer_update' }

sub prefix { 0 }

sub rectangles { @_ > 1 ? $_[0]->{rectangles} = $_[1] : $_[0]->{rectangles} }

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    return unless defined $chunk && length $chunk > 0;

    $self->{buffer} .= $chunk;

    if ($self->state ne 'rectangles') {
        return 1 unless length $self->{buffer} >= 4;

        $self->{number} = int(join('', unpack('n', substr($self->{buffer}, 2, 2))));
        $self->state('rectangles');

        $self->{offset} = 4;

        warn "number=" . $self->{number};
    }

    my $number = $self->{number};
    my $ri = scalar @{$self->rectangles};

    for (my $i = $ri; $i < $number; $i++) {
        return 1 unless length($self->{buffer}) - $self->{offset} >= 12;
        my $r = substr($self->{buffer}, $self->{offset}, 12);

        my @data = unpack('nnnnN', $r);
        my $rectangle =
          { x        => $data[0],
            y        => $data[1],
            width    => $data[2],
            height   => $data[3],
            encoding => Protocol::RFB::Encodings->encoding(int($data[4]))
          };

        if ($rectangle->{encoding} eq 'Raw') {
            my $rectangle_length =
                $rectangle->{width} 
              * $rectangle->{height}
              * ($self->{pixel_format}->bits_per_pixel / 8);

            return 1 unless length ($self->{buffer}) - 12 - $self->{offset} == $rectangle_length;

            my $encoding =
              Protocol::RFB::Encoding::Raw->new(
                bits_per_pixel => $self->{pixel_format}->bits_per_pixel);

            my $block =
              substr($self->{buffer}, $self->{offset} + 12,
                $rectangle_length);
            my $rv = $encoding->parse($block);
            return unless defined $rv;
            return 1 if $rv == -1;

            $self->{offset} += 12 + $rectangle_length;

            $rectangle->{data} = [];

            my $bpp = $self->{pixel_format}->bits_per_pixel / 8;

            my $i = 0;
            foreach my $pixel_raw (@{$encoding->pixels}) {
                my $pixel = unpack "C$bpp" => join '' => reverse split // => $pixel_raw;
                warn "pixel=$pixel";

                my $x = $i % $rectangle->{width} + $rectangle->{x};
                my $y = int($i / $rectangle->{width}) + $rectangle->{y};
                warn "x=$x";
                warn "y=$y";
                my $red = ($pixel >> $self->{pixel_format}->red_shift) & $self->{pixel_format}->red_max;
                my $green = ($pixel >> $self->{pixel_format}->green_shift) & $self->{pixel_format}->green_max;
                my $blue = ($pixel >> $self->{pixel_format}->blue_shift) & $self->{pixel_format}->blue_max;
                warn "color=$red $green $blue";
                push @{$rectangle->{data}}, {x => $x, y => $y, color => [$red, $green, $blue]};
                $i++;
            }

            push @{$self->rectangles}, $rectangle;
        }
        else {
            die 'Unsupported encoding';
        }
    }

    $self->state('done');

    return 1;
}

1;
