#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use_ok('Protocol::RFB::Message::Server');

ok(not defined Protocol::RFB::Message::Server->new->parse());
ok(not defined Protocol::RFB::Message::Server->new->parse(''));

# FramebufferUpdate
my $m = Protocol::RFB::Message::Server->new(bits_per_pixel => 8);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnnnNC', 5, 14, 1, 1, 0, 255)));
ok($m->is_done);
is($m->name, 'framebuffer_update');

# SetColorMapEntries
$m = Protocol::RFB::Message::Server->new;
ok($m->parse(pack('C', 1)));
ok(!$m->is_done);
ok($m->parse(pack('C', 0)));
ok(!$m->is_done);
ok($m->parse(pack('n', 123)));
ok(!$m->is_done);
ok($m->parse(pack('n', 1)));
ok(!$m->is_done);
ok($m->parse(pack('nnn', 1, 2, 3)));
ok($m->is_done);
is($m->name, 'set_color_map_entries');

# Bell
$m = Protocol::RFB::Message::Server->new;
ok($m->parse(pack('C', 2)));
ok($m->is_done);
is($m->name, 'bell');

# ServerCutText
#$m = Protocol::RFB::Message::Server->new;
#ok($m->parse(pack('C', 3)));
#ok($m->is_done);
#is($m->name, 'server_cut_text');
