# Copyright (c) 2013 Mitchell Cooper
# Provides an interface for CPAN
package API::Module::CPAN;

use warnings;
use strict;
use utf8;

use API::Module;

our $mod = API::Module->new(
    name          => 'CPAN',
    version       => '1.0',
    description   => 'provides an interface for the Comprehensive Perl Archive Network',
    depends_perl  => [],
    depends_base  => ['Commands', 'HTTP'],
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

$mod
