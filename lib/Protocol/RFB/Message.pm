package Protocol::RFB::Message;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{state} = 'init';
    $self->{buffer} = '';

    return $self;
}

sub state { @_ > 1 ? $_[0]->{state} = $_[1] : $_[0]->{state} }

sub is_done {shift->state eq 'done'}

1;
