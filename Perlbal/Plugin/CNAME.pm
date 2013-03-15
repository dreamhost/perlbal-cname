package Perlbal::Plugin::CNAME;

use strict;
use warnings;

use Net::DNS::Resolver;


my $WEBSITE_URI = $ENV{'WEBSITE_URI'};

sub register {
    my ($class, $service) = @_;
    $service->register_hook('CNAME', 'start_http_request',
        \&modify_host_header);
}


sub modify_host_header {
    my $cp = shift;

    my $host = $cp->{req_headers}->header('host');
    $host =~ s/:\d+$//;  # strip the port off

    my $requestLine = $cp->{req_headers}->{requestLine};
    my ($method, $path, $http_version) = $requestLine =~ /(\w+)\s+(.+)\s+(.+)/;
    my $uri = $cp->{req_headers}->{uri};
    my ($path) = $uri =~ m{http://.+?(/.+)}i;
    $path ||= '/';

    # let's look for only CNAMEs
    my $res = Net::DNS::Resolver->new(
        nameservers => [qw(66.33.206.206)], recurse => 0, debug => 0);
    my $query = $res->search($host, 'CNAME');

    return 0 unless $query;

    my @answers = $query->answer;
    my $cname = $answers[0]->cname or return 0;
    if ($cname =~ /\Q$WEBSITE_URI\E/) {
        $cp->{req_headers}->header('host', $cname);
    }

    return 0;
}


sub unregister {
    my ($class, $service) = @_;
    $service->unregister_hooks('CNAME');
}


sub load {return 1;}
sub unload {return 1;}


1;
