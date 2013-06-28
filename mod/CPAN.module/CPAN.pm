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
    version       => '1.1',
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

$mod
