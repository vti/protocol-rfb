#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use_ok('Protocol::RFB::Framebuffer');

my $b = Protocol::RFB::Framebuffer->new(width => 2, height => 3);
is($b->size, 6);

$b->set_rectangle(0, 0, 2, 3,
    [[1, 1, 1], [2, 2, 2], [3, 3, 3], [4, 4, 4], [5, 5, 5], [6, 6, 6]]);
is_deeply($b->buffer, [[1, 1, 1], [2, 2, 2], [3, 3, 3], [4, 4, 4], [5, 5, 5], [6, 6, 6]]);

$b->reset;
$b->set_rectangle(1, 1, 1, 1, [[5, 5, 5]]);
is_deeply($b->buffer, [
    [0, 0, 0], [0, 0, 0],
    [0, 0, 0], [5, 5, 5],
    [0, 0, 0], [0, 0, 0]
]);

$b->reset;
$b->set_rectangle(10, 10, 1, 1, [[5, 5, 5]]);
is_deeply($b->buffer, [
    [0, 0, 0], [0, 0, 0],
    [0, 0, 0], [0, 0, 0],
    [0, 0, 0], [0, 0, 0]
]);

$b->reset;
$b->set_rectangle(
    1, 1, 3, 3,
    [   [5, 5, 5], [5, 5, 5], [5, 5, 5],
        [5, 5, 5], [5, 5, 5], [5, 5, 5],
        [5, 5, 5], [5, 5, 5], [5, 5, 5]
    ]
);
is_deeply($b->buffer, [
    [0, 0, 0], [0, 0, 0],
    [0, 0, 0], [5, 5, 5],
    [0, 0, 0], [5, 5, 5]
]);

$b = Protocol::RFB::Framebuffer->new(width => 1, height => 2, x => 1, y => 1);
is($b->size, 2);
$b->set_rectangle(
    0, 0, 3, 3,
    [   [3, 3, 3], [3, 3, 3], [3, 3, 3],
        [3, 3, 3], [5, 5, 5], [3, 3, 3],
        [3, 3, 3], [3, 3, 3], [3, 3, 3]
    ]
);
is_deeply($b->buffer, [
    [5, 5, 5],
    [3, 3, 3]
]);
