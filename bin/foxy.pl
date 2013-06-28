#!/usr/bin/perl
# Copyright (c) 2013, Mitchell Cooper
our ($loop, $api, $irc, $foxy, $bot, $conf, $config);
package Foxy;

use strict;
use warnings;
use 5.010;

our $VERSION = '1.0';

our %dir;
BEGIN {
    unshift(@INC,
    
        # main.
        $dir{main} = shift @ARGV || '.',
        $dir{lib}  = "$dir{main}/lib",
        $dir{etc}  = "$dir{main}/etc",
        $dir{mod}  = "$dir{main}/mod",
        
        # submodules.
        $dir{eo} = "$dir{lib}/evented-object/lib",
        $dir{ec} = "$dir{lib}/evented-configuration/lib",
        $dir{ei} = "$dir{lib}/evented-irc/lib",
        $dir{ae} = "$dir{lib}/api-engine",
        
    );
}

use IO::Async::Loop;
use IO::Async::Stream;

use Evented::Object;
use Evented::Configuration;
use Evented::IRC;
use Evented::IRC::Async;
use API;

use parent 'Evented::Object';

our (
    $loop,              # IO::Async loop.
    $api,               # API manager object.
    $irc,               # libirc object.
    $foxy,              # bot Evented::Object.
    $conf               # Evented::Configuration object.
);

# parse configuration.
$conf = Evented::Configuration->new(conffile => "$dir{etc}/foxy.conf");
$conf->parse_config();
sub conf { $conf->get(@_) }

# create foxy object.
$foxy = Foxy->new();

# Initialization subroutine
sub bot_init {

    # Create loop
    $loop = IO::Async::Loop->new;
    
    # create the API manager object.
    $api = API->new(
        log_sub  => sub { say "[API] ".shift() },
        mod_dir  => $dir{mod},
        base_dir => "$dir{lib}/API/Base"
    );

    # create libirc server object.
    $irc = Evented::IRC::Async->new(
        host => conf('irc', 'host'),
        port => conf('irc', 'port'), # TODO: bind address.
        nick => conf('bot', 'nick'),
        user => conf('bot', 'user'),
        real => conf('bot', 'real'),
        sasl_user => conf('irc', 'sasl_user'),
        sasl_pass => conf('irc', 'sasl_pass')
    );
    
    # compatibility with older modules.
($main::loop, $main::api, $main::irc, $main::foxy, $main::bot, $main::conf, $main::config) =
($loop,       $api,       $irc,       $foxy,       $foxy,      $conf,       $conf        );
    
    # load configuration modules.
    load_api_modules();
    
    # connect to IRC.
    $loop->add($irc);
    apply_irc_handlers($irc);
    $irc->connect(on_error => sub { die 'IRC connection error' });
    
    # debug.
    $irc->on(raw  => sub { print "[~R] @_[2..$#_]\n"        }, priority => 200);
    $irc->on(send => sub { print "[~foxy] -> @_[1..$#_]\n"  }, priority => 200);
    
    $loop->run;    
}

# load API modules from configuration.
sub load_api_modules {
    $api->load_module($_) foreach $conf->keys_of_block('modules');
}


# Attach events to IRC object.
sub apply_irc_handlers {
    my $irc = shift;
    
    $irc->{autojoin} = conf('irc', 'autojoin');

    # handle PRIVMSG.
    $irc->on(privmsg => sub {
        my ($event, $user, $channel, $message) = @_;
        return unless $channel->isa('Evented::IRC::Channel'); # ignore PMs for now.
        return if !defined $message || !length $message;
        
        my $command = lc((split /\s/, $message)[0]);
        $command    =~ m/^\!(\w+)$/ or return; $command = $1;
        my @args    = split /\s/, $message;
        @args       = @args[1..$#args];
        
        # fire command.
        $foxy->fire("command_$command" => $user, $channel, @args);
        
    });
    
    # nick taken.
    $irc->on(nick_taken => sub {
        my ($event, $nick) = @_;
        $irc->send_nick($nick.q(_));
    });
    
}

bot_init();
