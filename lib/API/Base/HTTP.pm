# Copyright (c) 2013 Mitchell Cooper 
package API::Base::HTTP;

use warnings;
use strict;

use Net::Async::HTTP;
use Scalar::Util 'blessed';
use URI;

our $http = Net::Async::HTTP->new;
$Foxy::loop->add($http);

# does an HTTP request.
sub http_request {
    my ($module, %opts) = @_;
    my $fname = $module->full_name;

    # make sure all required options are present.
    foreach my $what (qw|uri callback|) {
        next if exists $opts{$what};
        $main::api->log2("module $fname didn't provide '$what' option for http_request()");
        return;
    }
    
    # if uri is not a URI object, make it so.
    $opts{uri} = URI->new($opts{uri}) unless blessed $opts{uri};
    
    # make sure callback is CODE.
    if (ref $opts{callback} ne 'CODE') {
        $main::api->log2("module $fname didn't supply CODE for http_request()");
        return;
    }
    
    # create the event callback.
    my $e_name = $module->unique_callback('httpRequest', $opts{uri}->as_string);
    $main::bot->register_event($e_name => $opts{callback}, name => $e_name);
    
    # do the request.
    $http->do_request(
        %opts,
        on_response => sub {
            my $response = shift;
            $main::bot->fire_event($e_name => $response, undef);
            $main::bot->delete_event($e_name);
        },
        on_error    => sub {
            my $message = shift;
            $main::bot->fire_event($e_name => undef, $message);
            $main::bot->delete_event($e_name);
        }
    );
    
    return 1;
}

# unload.
sub _unload {
    my ($class, $mod) = @_;
    return 1;
}

1
