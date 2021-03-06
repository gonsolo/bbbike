#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
BEGIN {
    # Don't use "use lib", so we are sure that the real BBBikeXS.pm/so is
    # loaded first
    push @INC, qw(../.. ../../lib);
}

use Data::Dumper;
use Getopt::Long;

use Strassen::Util;
use BBBikeXS; # must be loaded AFTER Strassen::Util, for some reasons

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test module\n";
	exit;
    }
}

my @tests = (
	     [[1000,1234],[1234,42]],
	     [[0,0],[0,100000]],
	     [[-1000,-123],[-1234,+123]],
	     [[rand(100000),rand(100000)],[rand(100000),rand(100000)]],
	     [[46452.8749304922,40778.1643650622],[76678.0142477852,4261.91260075441]],
	    );

plan tests => 4 + @tests * 2;

my $v;
my $bench;
GetOptions(
	   "v" => \$v,
	   "bench" => \$bench,
	  )
    or die "usage: $0 [-v] [-bench]\n";

{
    my $ref_wo = \&Strassen::Util::strecke; $ref_wo = "$ref_wo";
    my $ref_xs = \&Strassen::Util::strecke_XS; $ref_xs = "$ref_xs";
    my $ref_pp = \&Strassen::Util::strecke_PP; $ref_pp = "$ref_pp";
    is $ref_wo, $ref_xs;
    isnt $ref_wo, $ref_pp;
}

{
    my $ref_wo2 = \&Strassen::Util::strecke_s; $ref_wo2 = "$ref_wo2";
    my $ref_xs2 = \&Strassen::Util::strecke_s_XS; $ref_xs2 = "$ref_xs2";
    my $ref_pp2 = \&Strassen::Util::strecke_s_PP; $ref_pp2 = "$ref_pp2";
    is $ref_wo2, $ref_xs2;
    isnt $ref_wo2, $ref_pp2;
}

for (@tests) {
    my($p1, $p2) = @$_;

    cmp_ok abs(Strassen::Util::strecke_PP($p1, $p2) - Strassen::Util::strecke_XS($p1, $p2)), "<", 1, "strecke @$p1 -> @$p2",
	or diag "strecke with the values " . Dumper($p1, $p2). ": PP=" . Strassen::Util::strecke_PP($p1, $p2) . ", XS=" . Strassen::Util::strecke_XS($p1, $p2);

    my $s1 = join(",",@$p1);
    my $s2 = join(",",@$p2);
    cmp_ok abs(Strassen::Util::strecke_s_PP($s1,$s2) - Strassen::Util::strecke_s_XS($s1,$s2)), "<", 1, "strecke_s $s1 -> $s2",
	or diag "strecke_s with the values " . Dumper($s1, $s2). ": PP=" . Strassen::Util::strecke_s_PP($s1, $s2) . ", XS=" . Strassen::Util::strecke_s_XS($s1, $s2);

    if ($v) {
	diag "strecke_PP:   " . Strassen::Util::strecke_PP($p1, $p2);
	diag "strecke_XS:   " . Strassen::Util::strecke_XS($p1, $p2);
	diag "strecke_s_PP: " . Strassen::Util::strecke_s_PP($s1,$s2);
	diag "strecke_s_XS: " . Strassen::Util::strecke_s_XS($s1,$s2);
    }

}

if ($bench) {
    require Benchmark;
    my($p1, $p2) = @{$tests[0]};
    my $s1 = join(",",@$p1);
    my $s2 = join(",",@$p2);
    Benchmark::timethese
	    (-1,
	     {'perl'   => sub { Strassen::Util::strecke_PP($p1, $p2) },
	      'xs'     => sub { Strassen::Util::strecke_XS($p1, $p2) },
	      'perl_s' => sub { Strassen::Util::strecke_s_PP($s1, $s2) },
	      'xs_s'   => sub { Strassen::Util::strecke_s_XS($s1, $s2) },
	     });
}

__END__
