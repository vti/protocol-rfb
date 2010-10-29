package Protocol::RFB::Client;

use strict;
use warnings;

use constant DEBUG => $ENV{PROTOCOL_RFB_DEBUG} ? 1 : 0;

use Protocol::RFB::Message::Version;
use Protocol::RFB::Message::Security;
use Protocol::RFB::Message::Authentication;
use Protocol::RFB::Message::SecurityResult;
use Protocol::RFB::Message::Init;

use Protocol::RFB::Message::Server;
use Protocol::RFB::Message::FramebufferUpdateRequest;
use Protocol::RFB::Message::SetEncodings;
use Protocol::RFB::Message::PointerEvent;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{state} = 'init';

    $self->{version}   ||= '3.7';
    $self->{encodings} ||= [qw/CopyRect Raw/];

    return $self;
}

sub password { @_ > 1 ? $_[0]->{password} = $_[1] : $_[0]->{password} }

sub done { shift->state('done') }
sub state { @_ > 1 ? $_[0]->{state} = $_[1] : $_[0]->{state} }
sub is_done { shift->state =~ /done/ }

sub encodings { @_ > 1 ? $_[0]->{encodings} = $_[1] : $_[0]->{encodings} }

sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }

sub pixel_format {
    @_ > 1 ? $_[0]->{pixel_format} = $_[1] : $_[0]->{pixel_format};
}

sub server_name {
    @_ > 1 ? $_[0]->{server_name} = $_[1] : $_[0]->{server_name};
}

sub on_handshake {
    @_ > 1 ? $_[0]->{on_handshake} = $_[1] : $_[0]->{on_handshake};
}

sub _new_version_message  { shift; Protocol::RFB::Message::Version->new(@_) }
sub _new_security_message { shift; Protocol::RFB::Message::Security->new(@_) }

sub _new_authentication_message {
    shift;
    Protocol::RFB::Message::Authentication->new(@_);
}

sub _new_security_result_message {
    shift;
    Protocol::RFB::Message::SecurityResult->new(@_);
}
sub _new_init_message   { shift; Protocol::RFB::Message::Init->new(@_); }
sub _new_server_message { shift; Protocol::RFB::Message::Server->new(@_) }

sub on_write { @_ > 1 ? $_[0]->{on_write} = $_[1] : $_[0]->{on_write} }
sub on_error { @_ > 1 ? $_[0]->{on_error} = $_[1] : $_[0]->{on_error} }

sub on_framebuffer_update {
    @_ > 1
      ? $_[0]->{on_framebuffer_update} = $_[1]
      : $_[0]->{on_framebuffer_update};
}

sub set_color_map_entries {
    @_ > 1
      ? $_[0]->{set_color_map_entries} = $_[1]
      : $_[0]->{set_color_map_entries};
}
sub on_bell { @_ > 1 ? $_[0]->{on_bell} = $_[1] : $_[0]->{on_bell} }

sub on_server_cut_text {
    @_ > 1
      ? $_[0]->{on_server_cut_text} = $_[1]
      : $_[0]->{on_server_cut_text};
}

sub write {
    my $self = shift;

    $self->on_write->($self, $_[0]);
}

sub error {
    my $self  = shift;
    my $error = shift;

    return $self->{error} unless $error;

    $self->{error} = $error;
    $self->on_error->($self, $error);

    return $self;
}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    warn '< ' . unpack 'h*' => $chunk if DEBUG;

    if ($self->state eq 'init') {
        warn 'Initialization state' if DEBUG;

        $self->state('handshake');

        $self->{handshake_res} = $self->_new_version_message;
    }

    my $state = $self->state;

    if ($state eq 'handshake') {
        warn 'Handshake state' if DEBUG;

        my $res = $self->{handshake_res};

        # Error
        return unless $res->parse($chunk);

        # Wait
        return 1 unless $res->is_done;

        my $req;
        my $res_name = $res->name;
        if ($res_name eq 'version') {
            warn 'Received version' if DEBUG;

            $req = $self->_new_version_message(major => 3, minor => 7);
            $self->{handshake_res} = $self->_new_security_message;
        }
        elsif ($res_name eq 'security') {
            warn 'Received security type' if DEBUG;

            # Check what kind of security is available
            $req = $self->_new_security_message(type => 2);
            $self->{handshake_res} = $self->_new_authentication_message;
        }
        elsif ($res_name eq 'authentication') {
            warn 'Received authentication' if DEBUG;

            $req = $self->_new_authentication_message(
                challenge => $res->challenge,
                password  => $self->password
            );
            $self->{handshake_res} = $self->_new_security_result_message;
        }
        elsif ($res_name eq 'security_result') {
            warn 'Received security result' if DEBUG;

            return $self->error($res->error) if $res->error;

            # Initialization
            $req = $self->_new_init_message;
            $self->{handshake_res} = $self->_new_init_message;
        }
        elsif ($res_name eq 'init') {
            warn 'Received settings' if DEBUG;

            delete $self->{handshake_res};

            $self->width($res->width);
            $self->height($res->height);

            $self->server_name($res->server_name);

            $self->pixel_format($res->format);

            $self->state('ready');

            my $pixel_format = $res->format;

            $self->write($pixel_format);

            $self->set_encodings($self->encodings);

            $self->on_handshake->($self);

            return 1;
        }

        warn '> ' . $req->to_hex . ' (' . $req->name . ')' if DEBUG;

        # Send request
        $self->write($req->to_string) if $req;

        return 1;
    }

    # Message from server
    elsif ($state eq 'ready') {
        while (length($chunk) > 0) {
            my $message = $self->{server_message};
            if (!$message || $message->is_done) {
                $message = $self->{server_message} =
                  $self->_new_server_message(
                    pixel_format => $self->pixel_format);
            }

            my $parsed = $message->parse($chunk);
            return unless defined $parsed;

            return 1 unless $message->is_done;

            $chunk = length($chunk) > $parsed ? substr($chunk, $parsed) : "";

            my $cb = 'on_' . $message->name;

            $self->$cb->($self, $message->submessage) if $self->$cb;
        }

        #$self->framebuffer_update_request(10, 10, 100, 100, 1);

        return 1;
    }

    else {
        warn "Unknown message from server";
        return 1;
    }

    return;
}

sub framebuffer_update_request {
    my $self = shift;
    my ($x, $y, $width, $height, $incremental) = @_;

    my $m = Protocol::RFB::Message::FramebufferUpdateRequest->new(
        x           => $x,
        y           => $y,
        width       => $width,
        height      => $height,
        incremental => $incremental || 0
    );

    $self->write($m->to_string);
}

sub set_encodings {
    my $self = shift;
    my ($encodings) = @_;

    my $m =
      Protocol::RFB::Message::SetEncodings->new(encodings => $encodings);

    $self->write($m->to_string);
}

sub pointer_event {
    my $self = shift;
    my ($x, $y, $mask) = @_;

    my $m = Protocol::RFB::Message::PointerEvent->new(
        x           => $x,
        y           => $y,
        button_mask => $mask
    );

    $self->write($m->to_string);
}

1;
