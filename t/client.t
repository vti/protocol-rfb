#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use_ok('Protocol::RFB::Client');

my $client = Protocol::RFB::Client->new(password => '123');

$client->handshake_cb(sub { });
$client->write_cb(sub { });

# Server sends version
$client->parse("RFB 003.007\x0a");
is($client->state, 'handshake');

# Server sends security types
$client->parse(pack('C', 1) . pack('C', 1));
is($client->state, 'handshake');

# Server sends authentication challenge
$client->parse(pack('C', 1) x 16);
is($client->state, 'handshake');

# Server sends security result
$client->parse(pack('N', 0));
is($client->state, 'handshake');

# Server sends initialization
ok($client->parse(pack('n', 800)));
ok($client->parse(pack('n', 600)));
ok( $client->parse(
        pack('ccccnnncccc3', 16, 24, 0, 1, 255, 255, 255, 8, 16, 0, 0)
    )
);
ok($client->parse(pack('N', 3)));
ok($client->parse('wow'));
is($client->state, 'ready');

# Server sends bell
ok($client->parse(pack('C', 2)));
