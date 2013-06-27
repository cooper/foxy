# Copyright (c) 2013 Mitchell Cooper
# Provides an interface for connecting to Omegle.com
package API::Module::Omegle;

use warnings;
use strict;
use utf8;
use API::Module;

BEGIN {
    my $dir = "$Foxy::dir{lib}/net-async-omegle";
    
    # add Net::Async::Omegle submodule directory if needed.
    if (!($dir ~~ @INC)) {
        unshift @INC, $dir;
    }
}

our $mod = API::Module->new(
    name          => 'Omegle',
    version       => '1.0',
    description   => 'provides an interface for connecting to Omegle.com',
    depends_perl  => ['Net::Async::Omegle'],
    initialize    => \&init,
    void          => \&void
);

our $om;

# initialize.
sub init {

    # create Net::Async::Omegle object.
    $om = $Foxy::om = $main::om = Net::Async::Omegle->new();
    $Foxy::loop->add($Foxy::om);
    
    # fetch Omegle status information for the first time.
    $om->update;

    # load the OmegleEvents base submodule.
    $mod->load_submodule('EventsBase') or return;

    # register the OmegleEvents API::Module base.
    my $events_base = $mod->{api}->get_module('Omegle.EventsBase') or return;
    $events_base->register_base('OmegleEvents') or return;

    # copy Foxy methods.
    *Foxy::om_say       = *om_say;
    *Foxy::om_connected = *om_connected;
    *Foxy::om_running   = *om_running;

    return 1;
}

# unload module.
sub void {

    $main::loop->remove($om);
    undef $main::om;
    undef $Foxy::om;
    undef $om;
    
    undef *Foxy::om_say;
    undef *Foxy::om_connected;
    undef *Foxy::om_running;
    
    return 1;
    
}

# send a message if connected.
sub om_say {
    my ($bot, $channel, $message) = @_;
    my $sess = $channel->{preferred_session} || $channel->{sess};
    
    # not connected.
    $main::bot->om_connected($channel) or return;
    
    $channel->send_privmsg("You: $message");
    $sess->say($message);
    
}

# check if a stranger is connected.
# if not, send an error and return false.
sub om_connected {
    my ($bot, $channel) = @_;
    my $sess = $channel->{preferred_session} || $channel->{sess};
    
    # yep.
    return 1 if $sess && $sess->connected;
    
    # nope.
    $channel->send_privmsg('No stranger is connected.');
    return;
    
}

# check if a session is running.
# if not, send an error and return false.
sub om_running {
    my ($bot, $channel) = @_;
    my $sess = $channel->{preferred_session} || $channel->{sess};
    
    # yep.
    return 1 if $sess && $sess->running;
    
    # nope.
    $channel->send_privmsg('No session is currently running.');
    return;
    
}

$mod
