#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use_ok('Protocol::RFB::Encoding::Raw');

my $m = Protocol::RFB::Encoding::Raw->new(bits_per_pixel => 8);
is_deeply($m->pixels, []);
ok($m->parse(pack('C', 255)));
is_deeply($m->pixels, [pack('C', 255)]);

$m = Protocol::RFB::Encoding::Raw->new(bits_per_pixel => 16);
ok($m->parse(pack('CC', 255, 124)));
is_deeply($m->pixels, [pack('CC', 255, 124)]);

$m = Protocol::RFB::Encoding::Raw->new(bits_per_pixel => 32);
ok($m->parse(pack('CCCC', 255, 124, 124, 123)));
is_deeply($m->pixels, [pack('CCCC', 255, 124, 124, 123)]);

$m = Protocol::RFB::Encoding::Raw->new(bits_per_pixel => 32);
is($m->parse(pack('CC', 255, 124)), -1);
is($m->parse(pack('CC', 124, 123)), 1);
is_deeply($m->pixels, [pack('CCCC', 255, 124, 124, 123)]);
