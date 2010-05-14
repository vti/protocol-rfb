#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;

use_ok('Protocol::RFB::Message::FramebufferUpdate');
use Protocol::RFB::Message::PixelFormat;

my $pixel_format = Protocol::RFB::Message::PixelFormat->new;
$pixel_format->true_color_flag(1);
$pixel_format->red_max(255);
$pixel_format->green_max(255);
$pixel_format->blue_max(255);
$pixel_format->red_shift(8);
$pixel_format->green_shift(0);
$pixel_format->blue_shift(0);

$pixel_format->bits_per_pixel(8);
my $m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok(not defined $m->parse());
ok(not defined $m->parse(''));

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 255)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [{x => 5, y => 14, color => []}]
        }
    ]
);

$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 2)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 254)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 6, 15, 1, 1, 0, 255)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [pack('C', 254)]
        },
        {   x        => 6,
            y        => 15,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [pack('C', 255)]
        },
    ]
);

$pixel_format->bits_per_pixel(16);
$m =
  Protocol::RFB::Message::FramebufferUpdate->new(
    pixel_format => $pixel_format);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 255)));
ok(!$m->is_done);
ok($m->parse(pack('C', 255)));
ok($m->is_done);
is_deeply(
    $m->rectangles,
    [   {   x        => 5,
            y        => 14,
            width    => 1,
            height   => 1,
            encoding => 'Raw',
            data     => [pack('CC', 255, 255)]
        }
    ]
);

