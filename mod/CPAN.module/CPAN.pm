# Copyright (c) 2013 Mitchell Cooper
# Provides an interface for CPAN
package API::Module::CPAN;

use warnings;
use strict;
use utf8;

use API::Module;

our $IDX = 'http://cpanidx.org/cpanidx';

our $mod = API::Module->new(
    name          => 'CPAN',
    version       => '1.3',
    description   => 'provides an interface for the Comprehensive Perl Archive Network',
    depends_perl  => ['JSON'],
    depends_bases => ['Commands', 'HTTP'],
    initialize    => \&init,
    void          => \&void
);

# command handlers.
my %commands = (
    cpandists => {
        description => 'query the number of distributions a CPAN author has',
        callback    => \&cmd_cpandists,
        name        => 'cpan.command.cpandists'
    },
    cpanauth => {
        description => 'fetch information about a CPAN author',
        callback    => \&cmd_cpanauth,
        name        => 'cpan.command.cpanauth'
    },
    cpanmod => {
        description => 'fetch information about a CPAN module',
        callback    => \&cmd_cpanmod,
        name        => 'cpan.command.cpanmod'
    }
);

# initialize.
sub init {
    JSON->import('decode_json');

    # register commands.
    foreach (keys %commands) {
        $mod->register_command(command => $_, %{$commands{$_}}) or return;
    }
    
    return 1;
}

# unload module.
sub void {
    
    return 1;
    
}

# cpandists command.
sub cmd_cpandists {
    my ($event, $user, $channel, @args) = @_;
    
    # not enough args.
    if (!scalar @args) {
        $channel->send_privmsg("$$user: cpandists queries the number of dists the specified author has.");
        return;
    }
    
    # do the request.
    $mod->http_request(
        uri      => "$IDX/json/dists/$args[0]",
        callback => sub {
            my ($event, $response) = @_;
            my $info = decode_json($response->content);
            my $num  = scalar @$info;
            
            # none.
            if (!$num) {
                $channel->send_privmsg("$$user: no distributions found.");
                return;
            }
            
            # show first five.
            my ($i, @dists) = 0;
            foreach my $dist (@$info) {
            
                # too many.
                if ($i == 5) {
                    push @dists, 'etc';
                    last;
                }
            
                push @dists, $dist->{dist_name};
                $i++;
            }
            
            # found some.
            $channel->send_privmsg("$$user: \2$$info[0]{cpan_id}\2 has \2$num\2 dists: ".join(', ', @dists).q(.));
            
        }
    );
}

# cpanauth command.
sub cmd_cpanauth {
    my ($event, $user, $channel, @args) = @_;
    
    # not enough args.
    if (!scalar @args) {
        $channel->send_privmsg("$$user: cpanauth fetches author information.");
        return;
    }
    
    # do the request.
    $mod->http_request(
        uri      => "$IDX/json/auth/$args[0]",
        callback => sub {
            my ($event, $response) = @_;
            my $info = decode_json($response->content);
            my $num  = scalar @$info;
            
            # none.
            if (!$num) {
                $channel->send_privmsg("$$user: author not found.");
                return;
            }

            # found info.
            $info     = $info->[0];
            my $email = uc $info->{email} eq 'CENSORED' ? q() : "($$info{email})";
            $channel->send_privmsg("$$user: \2$$info{fullname}\2 is $$info{cpan_id} $email");
            
        }
    );
}


# cpanmod command.
sub cmd_cpanmod {
    my ($event, $user, $channel, @args) = @_;
    
    # not enough args.
    if (!scalar @args) {
        $channel->send_privmsg("$$user: cpanmod fetches module information.");
        return;
    }
    
    # do the request.
    $mod->http_request(
        uri      => "$IDX/json/mod/$args[0]",
        callback => sub {
            my ($event, $response) = @_;
            my $info = decode_json($response->content);
            my $num  = scalar @$info;
            
            # none.
            if (!$num) {
                $channel->send_privmsg("$$user: module not found.");
                return;
            }

            # found info.
            $info = $info->[0];
            $channel->send_privmsg("$$user: \2$$info{mod_name}\2 $$info{mod_vers} is part of the $$info{dist_name} $$info{dist_vers} dist by $$info{cpan_id}.");
            
        }
    );
}

$mod
