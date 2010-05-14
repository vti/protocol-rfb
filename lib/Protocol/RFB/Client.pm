package Protocol::RFB::Client;

use strict;
use warnings;

use Protocol::RFB::Message::Version;
use Protocol::RFB::Message::Security;
use Protocol::RFB::Message::Authentication;
use Protocol::RFB::Message::SecurityResult;
use Protocol::RFB::Message::Init;

use Protocol::RFB::Message::Server;
use Protocol::RFB::Message::FramebufferUpdateRequest;
use Protocol::RFB::Message::SetEncodings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{state} = 'init';

    $self->{version} ||= '3.7';
    $self->{encodings} ||= ['Raw'];

    return $self;
}

sub password { @_ > 1 ? $_[0]->{password} = $_[1] : $_[0]->{password} }

sub state { @_ > 1 ? $_[0]->{state} = $_[1] : $_[0]->{state} }

sub is_done {shift->state =~ /done/}

sub encodings { @_ > 1 ? $_[0]->{encodings} = $_[1] : $_[0]->{encodings} }

sub width  { @_ > 1 ? $_[0]->{width}  = $_[1] : $_[0]->{width} }
sub height { @_ > 1 ? $_[0]->{height} = $_[1] : $_[0]->{height} }

sub handshake_cb {
    @_ > 1 ? $_[0]->{handshake_cb} = $_[1] : $_[0]->{handshake_cb};
}

sub _new_version_message {shift; Protocol::RFB::Message::Version->new(@_)}
sub _new_security_message {shift; Protocol::RFB::Message::Security->new(@_)}
sub _new_authentication_message {shift; Protocol::RFB::Message::Authentication->new(@_)}
sub _new_security_result_message {shift; Protocol::RFB::Message::SecurityResult->new(@_)}
sub _new_init_message {shift; Protocol::RFB::Message::Init->new(@_)}
sub _new_server_message {shift; Protocol::RFB::Message::Server->new(@_)}

sub write_cb { @_ > 1 ? $_[0]->{write_cb} = $_[1] : $_[0]->{write_cb} }
sub error_cb { @_ > 1 ? $_[0]->{error_cb} = $_[1] : $_[0]->{error_cb} }

sub framebuffer_update_cb {
    @_ > 1
      ? $_[0]->{framebuffer_update_cb} = $_[1]
      : $_[0]->{framebuffer_update_cb};
}

sub set_color_map_entries {
    @_ > 1
      ? $_[0]->{set_color_map_entries} = $_[1]
      : $_[0]->{set_color_map_entries};
}
sub bell_cb { @_ > 1 ? $_[0]->{bell_cb} = $_[1] : $_[0]->{bell_cb} }

sub server_cut_text_cb {
    @_ > 1
      ? $_[0]->{server_cut_text_cb} = $_[1]
      : $_[0]->{server_cut_text_cb};
}

sub parse {
    my $self = shift;
    my ($chunk) = @_;

    if ($self->state eq 'init') {
        $self->state('handshake');

        $self->{handshake_res} = $self->_new_version_message;
    }

    my $state = $self->state;

    if ($state eq 'handshake') {
        my $res = $self->{handshake_res};

        # Error
        return unless $res->parse($chunk);

        # Wait
        return 1 unless $res->is_done;

        my $req;
        my $res_name = $res->name;
        if ($res_name eq 'version') {
            warn "parsing version";
            $req = $self->_new_version_message(major => 3, minor => 7);
            $self->{handshake_res} = $self->_new_security_message;
        }
        elsif ($res_name eq 'security') {
            warn "parsing security";
            # Check was kind of security is available
            $req = $self->_new_security_message(type => 2);
            $self->{handshake_res} = $self->_new_authentication_message;
        }
        elsif ($res_name eq 'authentication') {
            warn "parsing authentication";
            $req = $self->_new_authentication_message(
                challenge => $res->challenge,
                password  => $self->password
            );
            $self->{handshake_res} = $self->_new_security_result_message;
        }
        elsif ($res_name eq 'security_result') {
            warn "parsing securityresult";
            return $self->error_cb($res->error) if $res->error;

            # Initialization
            $req = $self->_new_init_message;
            $self->{handshake_res} = $self->_new_init_message;
        }
        elsif ($res_name eq 'init') {
            delete $self->{handshake_res};

            $self->width($res->width);
            $self->height($res->height);

            $self->pixel_format($res->format);

            use Data::Dumper;
            warn Dumper $self;

            $self->state('ready');
            $self->handshake_cb->($self);

            my $pixel_format = $res->format;
            $self->write_cb->($self, $pixel_format);

            $self->set_encodings($self->encodings);

            #$self->framebuffer_update_request(0, 0, $res->width, $res->height, 0);
            $self->framebuffer_update_request(10, 10, 100, 100, 0);

            return 1;
        }

        # Send request
        $self->write_cb->($self, $req->to_string) if $req;

        return 1;
    }

    # Message from server
    elsif ($state eq 'ready') {
        my $message = $self->{server_message};
        if (!$message || $message->is_done) {
            warn 'New data!';
            $message = $self->{server_message} = $self->_new_server_message(
                pixel_format => $self->pixel_format);
        }

        return unless $message->parse($chunk);
        return 1 unless $message->is_done;

        if ($message->name eq 'framebuffer_update') {
            my $rectangles = $message->{message}->rectangles;
            foreach my $rectangle (@$rectangles) {
                use Imager;
                my $img = Imager->new(xsize => $rectangle->{width}, ysize =>
                    $rectangle->{height});

                warn "x=$rectangle->{x}";
                warn "y=$rectangle->{y}";
                warn "w=$rectangle->{width}";
                warn "h=$rectangle->{height}";

                my $i = 0;
                my $pixels = $rectangle->{data};
                foreach my $pixel (@$pixels) {
                    my $x = $i % $rectangle->{width};
                    my $y = int($i / $rectangle->{width});
                warn "x=$x";
                warn "y=$y";
                    my $red = (unpack('N', $pixel) >> $self->red_shift) & $self->red_max;
                    my $green = (unpack('N', $pixel) >> $self->green_shift) & $self->green_max;
                    my $blue = (unpack('N', $pixel) >> $self->blue_shift) & $self->blue_max;
                    warn "pixel=$red $green $blue";
                    $img->setpixel(x => $x, y => $y, color => [$red, $green, $blue]);
                    $i++;
                }
                $img->write(file => 'foo.jpg', type => 'jpeg') or die $img->errstr;
                undef $img;
            }
        }

        my $cb = $message->name . '_cb';
        warn "cb=" . $cb;

        $self->$cb->($self, $message) if $self->$cb;

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

    $self->write_cb->($self, $m->to_string);
}

sub set_encodings {
    my $self = shift;
    my ($encodings) = @_;

    my $m = Protocol::RFB::Message::SetEncodings->new(
        encodings => $encodings
    );

    $self->write_cb->($self, $m->to_string);
}

1;
