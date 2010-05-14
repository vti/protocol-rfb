package Protocol::RFB::Message::ServerCutText;

use strict;
use warnings;

use base 'Protocol::RFB::Message';

use overload '""' => \&to_string;

sub name { 'server_cut_text' }

sub prefix { 3 }

sub text { @_ > 1 ? $_[0]->{text} = $_[1] : $_[0]->{text} }

sub to_string {
    my $self = shift;

    my $length = length($self->text);

    my $text = pack('CC3N2', $self->prefix, 0, $length);
    $text .= $self->text;
    return $text;
}

1;
