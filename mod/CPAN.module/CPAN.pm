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
    version       => '1.6',
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
    },
    cpandist => {
        description => 'fetch information about a CPAN distribution',
        callback    => \&cmd_cpandist,
        name        => 'cpan.command.cpandist'
    },
    cpancore => {
        description => 'fetch information about a core perl module',
        callback    => \&cmd_cpancore,
        name        => 'cpan.command.cpancore'
    },
    cpanmirrors => {
        description => 'query the number of CPAN mirrors',
        callback    => \&cmd_cpanmirrors,
        name        => 'cpan.command.cpanmirrors'
    },
    cpanmirror => {
        description => 'fetches information about a CPAN mirror',
        callback    => \&cmd_cpanmirrors,
        name        => 'cpan.command.cpanmirror'
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
            $channel->send_privmsg(
                "$$user: \2$$info{mod_name}\2 $$info{mod_vers} is part " .
                "of the $$info{dist_name} $$info{dist_vers} dist by $$info{cpan_id}."
            );
            
        }
    );
}

# cpandist command.
sub cmd_cpandist {
    my ($event, $user, $channel, @args) = @_;
    
    # not enough args.
    if (!scalar @args) {
        $channel->send_privmsg("$$user: cpandist fetches distribution information.");
        return;
    }
    
    # do the request.
    $mod->http_request(
        uri      => "$IDX/json/dist/$args[0]",
        callback => sub {
            my ($event, $response) = @_;
            my $info = decode_json($response->content);
            my $num  = scalar @$info;
            
            # none.
            if (!$num) {
                $channel->send_privmsg("$$user: distribution not found.");
                return;
            }

            # found info.
            $info = $info->[0];
            $channel->send_privmsg(
                "$$user: \2$$info{dist_name}\2 $$info{dist_vers} is by $$info{cpan_id}" .
                " at $$info{dist_file}.");
            
        }
    );
}

# cpancore command.
sub cmd_cpancore {
    my ($event, $user, $channel, @args) = @_;
    
    # not enough args.
    if (!scalar @args) {
        $channel->send_privmsg("$$user: cpancore fetches information about core Perl modules.");
        return;
    }
    
    # do the request.
    $mod->http_request(
        uri      => "$IDX/json/corelist/$args[0]",
        callback => sub {
            my ($event, $response) = @_;
            my $info = decode_json($response->content);
            my $num  = scalar @$info;
            
            # none.
            if (!$num) {
                $channel->send_privmsg("$$user: $args[0] is not a core module.");
                return;
            }

            # determine if the module is deprecated and when.
            my $deprecated;
            foreach my $ver (@$info) {
                next unless $ver->{deprecated};
                $deprecated =
                    " \2DEPRECATED\2 since " . $ver->{released} . ' with perl ' .
                    version->parse($ver->{perl_ver})->normal .
                    ' and module version ' . $ver->{mod_vers}.q(.);
                last; 
            }

            # found info.
            use version 0.77;
            $channel->send_privmsg(
                "$$user: \2$args[0]\2 $$info[0]{mod_vers} became a core module with perl " .
                version->parse($info->[0]{perl_ver})->normal                        .
                ". The latest version $$info[$#$info]{mod_vers} ships with perl "  .
                version->parse($info->[$#$info]{perl_ver})->normal.q(.) . $deprecated || q()
            );
            
        }
    );
}

# cpanmirrors command.
sub cmd_cpanmirrors {
    my ($event, $user, $channel, @args) = @_;
    
    # do the request.
    $mod->http_request(
        uri      => "$IDX/json/mirrors",
        callback => sub {
            my ($event, $response) = @_;
            my $info = decode_json($response->content);
            my $num  = scalar @$info;
            
            # just the number.
            if (!scalar @args) {
                $channel->send_privmsg("$$user: There are \2$num\2 official CPAN mirrors.");
                return 1;
            }
            
            # find a match.
            my $mirror;
            foreach my $dst (@$info) {
                next unless $dst->{hostname} =~ m/$args[0]/;
                $mirror = $dst;
                last;
            }
            
            my $hoster    = $mirror->{dst_organisation} ? " by $$mirror{dst_organisation}" : q();
            my $location  = $mirror->{dst_location} ? " in $$mirror{dst_location}" : q();
            my $bandwidth = $mirror->{dst_bandwidth} ? " with $$mirror{dst_bandwidth} bandwidth" : q();
            my $updated   = $mirror->{frequency} ? " and is updated $$mirror{frequency}" : q();
            
            $channel->send_privmsg("$$user: \2$$mirror{hostname}\2 is hosted$hoster$location$bandwidth$updated.");
        }
    );
}

$mod
