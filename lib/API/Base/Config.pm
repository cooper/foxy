# COPYRIGHT (c) 2013 Mitchell Cooper 
package API::Base::Config;

use warnings;
use strict;

# fetches a value from the module's config block.
sub conf {
    my ($mod, $key) = @_;
    return $main::conf->get(['module', $mod->{name}], $key);
}

sub _unload {
    return 1;
}

1
