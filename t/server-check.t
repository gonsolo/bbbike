#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib ($FindBin::RealBin,
	 "$FindBin::RealBin/..",
	);

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
    if ($ENV{BBBIKE_TEST_NO_NETWORK}) {
        print "1..0 # skip due no network\n";
        exit;
    }
}

use Getopt::Long;
use IO::Socket::INET;
use URI;

use BBBikeVar qw();

use BBBikeTest qw($cgiurl check_cgi_testing);

check_cgi_testing;

my @urls;
GetOptions("url=s" => \@urls)
    or die "usage: $0 [-url ...]";

if (!@urls) {
    @urls = $cgiurl;
}

plan tests => 2 * @urls;

my $ua_string = "User-Agent: BBBike-Test/1.0 (raw sock)";

for my $_url (@urls) {
    my $u = URI->new($_url);
    my $host = $u->host;
    my $port = $u->port;
    my $peeraddr = "$host:$port";
    my $path = $u->path;

    my $get_sock = sub {
	my $sock = IO::Socket::INET->new(PeerAddr => $peeraddr)
	    or die "Cannot connect to $peeraddr: $!";
	$sock;
    };

    {
	my $sock = $get_sock->();
	print $sock "GET $path HTTP/1.0\r\n$ua_string\r\nHost: $host:$port\r\n\r\n";
	like(scalar <$sock>, qr/200 OK/, "single GET okay ($_url)");
    }

    TRY: for my $try (1..2) {
	my $sock = $get_sock->();
	print $sock "GET $path HTTP/1.1\r\n$ua_string\r\nHost: $host:$port\r\n\r\nGET $path HTTP/1.1\r\n$ua_string\r\nHost: $host:$port\r\nConnection: close\r\n\r\n";

	my $rest;
	read $sock,$rest,15000; # 15000 is enough to get first request and header of second...

	my $two_responses_qr = qr/200 OK.*200 OK/s;
	if ($rest =~ $two_responses_qr || $try == 2) {
	    like($rest, $two_responses_qr, "double GET okay (http pipelining, $_url)");
	    last TRY;
	} else {
	    # http://www-archive.mozilla.org/projects/netlib/http/pipelining-faq.html
	    # says: "If a connection fails or is dropped by the server
	    # partway into downloading a pipelined response, the web
	    # browser must be capable of restarting the lost
	    # requests." A lost connection may happen if an Apache is
	    # gracefully restarted (e.g. due to logrotation). So we
	    # immediately retry the request.
	    diag("First pipeline request (partially) failed, retry once");
	    sleep 1;
	}
    }
}

__END__
