#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok('Protocol::RFB::Encoding::CopyRect');

my $m = Protocol::RFB::Encoding::CopyRect->new;
is_deeply($m->parse(pack('n', 100) . pack('n', 200)), [100, 200]);
