#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

use LWP::UserAgent;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

plan tests => 3;

my $ua = LWP::UserAgent->new;
$ua->agent('BBBike-Test/1.0');
{
    my $resp = $ua->get('http://m.bbbike.de');
    ok $resp->is_success, 'm.bbbike.de';

    my $content = $resp->decoded_content;
    like $content, qr{<meta name="viewport"}, 'Found viewport tag';
    like $content, qr{BBBikeForm}, 'Found form name';
}

__END__