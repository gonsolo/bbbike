# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1999,2001,2004,2008,2010,2011,2014,2016 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://bbbike.de
#

package VectorUtil;

use strict;
use vars qw($VERSION $VERBOSE @ISA @EXPORT_OK);
$VERSION = 1.25;

require Exporter;
@ISA = 'Exporter';

@EXPORT_OK = qw(vector_in_grid project_point_on_line distance_point_line
		distance_point_rectangle get_polygon_center
		point_in_grid point_in_polygon move_point_orthogonal
		intersect_rectangles enclosed_rectangle normalize_rectangle
		azimuth offset_line bbox_of_polygon combine_bboxes
		triangle_area triangle_area_by_lengths
	       );

sub pi () { 4 * atan2(1, 1) } # 3.141592653

# Diese Funktion testet, ob sich ein Vektor innerhalb eines Gitters
# befindet. F�r Vektoren, bei denen mindestens einer der Punkte innerhalb
# des Gitters ist, ist die L�sung trivial. Interessanter ist es, wenn
# beide Punkte au�erhalb des Gitters sind, ein Teil des Vektors aber
# innerhalb.
# Siehe auch Grafik in ../misc/gridvectortest.fig
sub vector_in_grid {
    my($x1,$y1,$x2,$y2,$gridx1,$gridy1,$gridx2,$gridy2) = @_;

    # wenigstens ein Punkt ist innerhalb des Gitters
    return 7 if ($x1 >= $gridx1 && $x1 <= $gridx2 &&
		 $y1 >= $gridy1 && $y1 <= $gridy2);
    return 6 if ($x2 >= $gridx1 && $x2 <= $gridx2 &&
		 $y2 >= $gridy1 && $y2 <= $gridy2);

    # beide Punkte sind au�erhalb des Gitters
    return 0 if $x1 < $gridx1 && $x2 < $gridx1;
    return 0 if $x1 > $gridx2 && $x2 > $gridx2;
    return 0 if $y1 < $gridy1 && $y2 < $gridy1;
    return 0 if $y1 > $gridy2 && $y2 > $gridy2;

    my $sgn;
    my $ges_strecke = sqrt(($x1-$x2)*($x1-$x2) + ($y1-$y2)*($y1-$y2));

    if ($x1 != $x2) {
	# Schnittpunkt-Test am rechten Rand
	my $d_x1_gridx1 = ($gridx1 - $x1);
	my $a = $d_x1_gridx1*$ges_strecke/($x2-$x1);
	my $b = _pos_sqrt($a*$a - $d_x1_gridx1*$d_x1_gridx1);
	$sgn = ($y1 < $y2 ? 1 : -1);
	$sgn *= -1 if (($x1 < $x2 && $x1 > $gridx1) ||
		       ($x2 < $x1 && $x1 < $gridx1));
	my $schnitt_y_gridx1 = $y1 + $sgn*$b;

	if ($schnitt_y_gridx1 >= $gridy1 &&
	    $schnitt_y_gridx1 <= $gridy2) {
	    warn "Gefunden: $gridy1 <= $schnitt_y_gridx1 <= $gridy2\n" if $VERBOSE;
	    return 1;
	}

	# Schnittpunkt-Test am linken Rand
	my $d_x1_gridx2 = ($gridx2 - $x1);
	$a = $d_x1_gridx2*$ges_strecke/($x2-$x1);
	$b = _pos_sqrt($a*$a - $d_x1_gridx2*$d_x1_gridx2);
	$sgn = ($y1 < $y2 ? 1 : -1);
	$sgn *= -1 if (($x1 < $x2 && $x1 > $gridx2) ||
		       ($x2 < $x1 && $x1 < $gridx2));
	my $schnitt_y_gridx2 = $y1 + $sgn*$b;

	if ($schnitt_y_gridx2 >= $gridy1 &&
	    $schnitt_y_gridx2 <= $gridy2) {
	    warn "Gefunden: $gridy1 <= $schnitt_y_gridx2 <= $gridy2\n" if $VERBOSE;
	    return 2;
	}
    }

    if ($y2 != $y1) {
	# Schnittpunkt-Test am oberen Rand (geometrisch unten)
	my $d_y1_gridy2 = ($gridy2 - $y1);
	my $a = $d_y1_gridy2*$ges_strecke/($y2-$y1);
	my $b = _pos_sqrt($a*$a - $d_y1_gridy2*$d_y1_gridy2);
	$sgn = ($x1 < $x2 ? 1 : -1);
	$sgn *= -1 if (($y1 < $y2 && $y1 > $gridy2) ||
		       ($y2 < $y1 && $y1 < $gridy2));
	my $schnitt_x_gridy2 = $x1 + $sgn*$b;

	if ($schnitt_x_gridy2 >= $gridx1 &&
	    $schnitt_x_gridy2 <= $gridx2) {
	    warn "Gefunden: $gridx1 <= $schnitt_x_gridy2 <= $gridx2\n" if $VERBOSE;
	    return 4;
	}

	# Schnittpunkt-Test am unteren Rand (geometrisch oben)

	my $d_y1_gridy1 = ($gridy1 - $y1);
	$a = $d_y1_gridy1*$ges_strecke/($y2-$y1);
	$b = _pos_sqrt($a*$a - $d_y1_gridy1*$d_y1_gridy1);
	$sgn = ($x1 < $x2 ? 1 : -1);
	$sgn *= -1 if (($y1 < $y2 && $y1 > $gridy1) ||
		       ($y2 < $y1 && $y1 < $gridy1));
	my $schnitt_x_gridy1 = $x1 + $sgn*$b;

	if ($schnitt_x_gridy1 >= $gridx1 &&
	    $schnitt_x_gridy1 <= $gridx2) {
	    warn "Gefunden: $gridx1 <= $schnitt_x_gridy1 <= $gridx2\n" if $VERBOSE;
	    return 3;
	}
    }

    0;
}

# in: point ($px,$py)
#     line ($s0x,$s0y) - ($s1x,$s1y)
# out: point($x,$y) (projected point on the line)
sub project_point_on_line {
    my($px,$py,$s0x,$s0y,$s1x,$s1y) = @_;
    my($sxd, $syd) = ($s1x-$s0x, $s1y-$s0y);
    if ($sxd+$syd==0) { # line is really a point
	return sqrt(sqr($px-$s0x)+sqr($py-$s0y));
    }
    my $tf = (($px-$s0x)*($s1x-$s0x) + ($py-$s0y)*($s1y-$s0y)) /
	     ($sxd*$sxd + $syd*$syd);
    # $nx/$ny: nearest point on line
    my $nx = $s0x+$tf*$sxd;
    my $ny = $s0y+$tf*$syd;
    ($nx, $ny);
}

# in: point ($px,$py)
#     line ($s0x,$s0y) - ($s1x,$s1y)
# out: minimum distance from point to line
sub distance_point_line {
    my($px,$py,$s0x,$s0y,$s1x,$s1y) = @_;
    my($sxd, $syd) = ($s1x-$s0x, $s1y-$s0y);
    if ($sxd+$syd==0) { # line is really a point
	return sqrt(sqr($px-$s0x)+sqr($py-$s0y));
    }
    my $tf = (($px-$s0x)*($s1x-$s0x) + ($py-$s0y)*($s1y-$s0y)) /
	     ($sxd*$sxd + $syd*$syd);
    # $nx/$ny: nearest point on line
    my $nx = $s0x+$tf*$sxd;
    my $ny = $s0y+$tf*$syd;
    if ((($nx >= $s0x && $nx <= $s1x) || ($nx >= $s1x && $nx <= $s0x))
	&&
	(($ny >= $s0y && $ny <= $s1y) || ($ny >= $s1y && $ny <= $s0y))
       ) {
	my $dx = $s0x-$px+$tf*$sxd;
	my $dy = $s0y-$py+$tf*$syd;
	sqrt($dx*$dx+$dy*$dy);
    } else {
	# nearest point is out of line ... check the endpoints of the line
	my $dist0 = sqrt(sqr($s0x-$px) + sqr($s0y-$py));
	my $dist1 = sqrt(sqr($s1x-$px) + sqr($s1y-$py));
	if ($dist0 < $dist1) {
	    $dist0;
	} else {
	    $dist1;
	}
    }
}

# in: point ($px,$py)
#     rectangle ($left,$top,$right,$bottom)
# out: minimum distance from point to rectangle outline
sub distance_point_rectangle {
    my($px,$py,$left,$top,$right,$bottom) = @_;
    my $dist;
    for my $line_def (
		      [$left,$top,$right,$top],
		      [$right,$top,$right,$bottom],
		      [$right,$bottom,$left,$bottom],
		      [$left,$bottom,$left,$top],
		     ) {
	my $this_dist = distance_point_line($px,$py,@$line_def);
	if (!defined $dist || $this_dist < $dist) {
	    $dist = $this_dist;
	}
    }
    $dist;
}

# Return the approximated center of an polygon.
# Coordinates of the polygon are supplied in @koord (flat list of x and y
# values).
#XXX original source?
#XXX this algorithm seems to have problems with certain polygons (just test: Paul-L�be-Haus from bbbike/data/sehenswuerdigkeit)
sub get_polygon_center {
    my(@koord) = @_;

    # make closed polygon:
    if ($koord[0] != $koord[-2] && $koord[1] != $koord[-1]) {
	push @koord, @koord[0,1];
    }

    my $n = 0;
    my($sumx, $sumy) = (0, 0);
    my $ovfl = 0;
    my $step = 1;
    for(my $inx = 0; $inx < $#koord-2; $inx+=2) {
	my($x1,$y1, $x2,$y2) = (@koord[$inx..$inx+3]);
	my $len = sqrt(sqr($x1-$x2) + sqr($y1-$y2));
	next if $len == 0;
	my($ex,$ey) = ($step*($x2-$x1)/$len,$step*($y2-$y1)/$len);
	my($sx,$sy) = ($x1,$y1);
	if ($ovfl > 0) {
	    my $ovfl_x = $ex/$step*$ovfl;
	    my $ovfl_y = $ey/$step*$ovfl;
	    next if (abs($ovfl_x) > abs($x2-$x1) ||
		     abs($ovfl_y) > abs($y2-$y1));
	    $sx += $ovfl_x;
	    $sy += $ovfl_y;
	}
	my $x_cmp = ($sx < $x2);
	my $y_cmp = ($sy < $y2);
	my $oldn = $n;
	while ((($x_cmp && $sx < $x2) ||
		(!$x_cmp && $sx > $x2)) &&
	       (($y_cmp && $sy < $y2) ||
		(!$y_cmp && $sy > $y2))) {
	    $sumx += $sx;
	    $sumy += $sy;
	    $n++;

	    $sx += $ex;
	    $sy += $ey;
	}

	if ($oldn < $n) {
	    $ovfl = sqrt(sqr($x2-($sx-$ex))+sqr($y2-($sy-$ey)));
	} else {
	    $ovfl -= sqrt(sqr($x2-$sx)+sqr($y2-$sy));
	}
    }
    if ($n != 0) {
	($sumx/$n, $sumy/$n);
    } else {
	undef;
    }
}

# only for parallel rectangles, does not check for enclosed rectangles
sub intersect_rectangles {
    my($ax,$ay,$bx,$by, $cx,$cy,$dx,$dy) = @_;
    # horizontal against vertical
    return 1 if intersect_lines($ax,$ay,$bx,$ay, $cx,$cy,$cx,$dy);
    return 1 if intersect_lines($ax,$ay,$bx,$ay, $dx,$cy,$dx,$dy);
    return 1 if intersect_lines($ax,$by,$bx,$by, $cx,$cy,$cx,$dy);
    return 1 if intersect_lines($ax,$by,$bx,$by, $dx,$cy,$dx,$dy);

    # vertical against horizontal
    return 1 if intersect_lines($ax,$ay,$ax,$by, $cx,$cy,$dx,$cy);
    return 1 if intersect_lines($ax,$ay,$ax,$by, $cx,$dy,$dx,$dy);
    return 1 if intersect_lines($bx,$ay,$bx,$by, $cx,$cy,$dx,$cy);
    return 1 if intersect_lines($bx,$ay,$bx,$by, $cx,$dy,$dx,$dy);

    0;
}

# Return true if inner rectangle is enclosed in outer rectangle
sub enclosed_rectangle {
    my($outer_x0,$outer_y0,$outer_x1,$outer_y1,
       $inner_x0,$inner_y0,$inner_x1,$inner_y1) = @_;
    return ($inner_x0 >= $outer_x0 && $inner_y0 >= $outer_y0 &&
	    $inner_x1 <= $outer_x1 && $inner_y1 <= $outer_y1);
}

# from mapsearch.c
sub intersect_lines {
    my($ax,$ay,$bx,$by, $cx,$cy,$dx,$dy) = @_;

    my $numerator = (($ay-$cy)*($dx-$cx) - ($ax-$cx)*($dy-$cy));
    my $denominator = (($bx-$ax)*($dy-$cy) - ($by-$ay)*($dx-$cx));

    if (($denominator == 0) && ($numerator == 0)) { # lines are coincident, intersection is a line segement if it exists
	if ($ay == $cy) { # coincident horizontally, check x's
	    if ((($ax >= min($cx,$dx)) && ($ax <= max($cx,$dx))) || (($bx >= min($cx,$dx)) && ($bx <= max($cx,$dx)))) {
		return 1;
	    } else {
		return 0;
	    }
	} else { # test for y's will work fine for remaining cases
	    if ((($ay >= min($cy,$dy)) && ($ay <= max($cy,$dy))) || (($by >= min($cy,$dy)) && ($by <= max($cy,$dy)))) {
		return 1;
	    } else {
		return 0;
	    }
	}
    }

    if ($denominator == 0) { # lines are parallel, can't intersect
	return 0;
    }

    my $r = $numerator/$denominator;

    if (($r<0) || ($r>1)) {
	return 0; # no intersection
    }

    $numerator = (($ay-$cy)*($bx-$ax) - ($ax-$cx)*($by-$ay));
    my $s = $numerator/$denominator;

    if (($s<0) || ($s>1)) {
	return 0; # no intersection
    }

    1;
}

# Previously in Geometry.pm as get_intersection
sub intersect_line_rectangle {
    my($x1,$y1, $x2,$y2,
       $rectx1,$recty1,$rectx2,$recty2) = @_;

    # normieren
    if ($y1 > $y2) {
	($x1, $x2, $y1, $y2) = ($x2, $x1, $y2, $y1);
    }
    if ($rectx1 > $rectx2) {
	($rectx1, $rectx2) = ($rectx2, $rectx1);
    }
    if ($recty1 > $recty2) {
	($recty1, $recty2) = ($recty2, $recty1);
    }

    # obere Kante
    if ($y2 > $recty1 && $y1 < $recty1) {
	my $ix = $x1 + ($x2-$x1)/($y2-$y1)*($recty1-$y1);
	if ($ix >= $rectx1 and $ix <= $rectx2) {
	    return ($ix, $recty1);
	}
    }

    # untere Kante
    if ($y2 > $recty2 && $y1 < $recty2) {
	my $ix = $x1 + ($x2-$x1)/($y2-$y1)*($recty2-$y1);
	if ($ix >= $rectx1 and $ix <= $rectx2) {
	    return ($ix, $recty2);
	}
    }

    # normieren
    if ($x1 > $x2) {
	($x1, $x2, $y1, $y2) = ($x2, $x1, $y2, $y1);
    }

    # linke Kante
    if ($x2 > $rectx1 && $x1 < $rectx1) {
	my $iy = $y1 + ($y2-$y1)/($x2-$x1)*($rectx1-$x1);
	if ($iy >= $recty1 and $iy <= $recty2) {
	    return ($rectx1, $iy);
	}
    }

    # rechte Kante
    if ($x2 > $rectx2 && $x1 < $rectx2) {
	my $iy = $y1 + ($y2-$y1)/($x2-$x1)*($rectx2-$x1);
	if ($iy >= $recty1 and $iy <= $recty2) {
	    return ($rectx2, $iy);
	}
    }

    return ();
}

sub point_in_grid {
    my($x1,$y1,$gridx1,$gridy1,$gridx2,$gridy2) = @_;
    return ($x1 >= $gridx1 && $x1 <= $gridx2 &&
	    $y1 >= $gridy1 && $y1 <= $gridy2);
}

# This is translated from msPointInPolygon from mapsearch.c from
# mapserver 3.6.4:
sub point_in_polygon {
    my($p,$poly) = @_;
    my $status = 0;
    my($px,$py) = @$p;

    for(my $i = 0, my $j = $#$poly;
	$i <= $#$poly;
	$j = $i++
       ) {
	if (((($poly->[$i][1] <= $py) &&
	      ($py < $poly->[$j][1])) ||
	     (($poly->[$j][1] <= $py) &&
	      ($py < $poly->[$i][1]))) &&
	    ($px < ($poly->[$j][0] - $poly->[$i][0]) * ($py - $poly->[$i][1]) / ($poly->[$j][1] - $poly->[$i][1]) + $poly->[$i][0])) {
	    $status = !$status;
	}
    }

    return $status;
}

# Move point $p1/$p2 by $delta points orthogonal to the line $x1/$y1 -
# $x2/$y2. In Tk::Canvas-like coordinate systems (y grows to bottom),
# positive $delta means move to the right, negative to the left.
sub move_point_orthogonal {
    die "Needs exactly seven arguments" if @_ != 7;
    my($p1,$p2, $x1,$y1,$x2,$y2, $delta) = @_;
    my $alpha = atan2($y2-$y1, $x2-$x1);
    my $beta  = $alpha + pi/2;
    my($dx, $dy) = ($delta*cos($beta), $delta*sin($beta));
    ($p1+$dx, $p2+$dy);
}

sub normalize_rectangle {
    my(@r) = @_;
    ($r[2], $r[0]) = ($r[0], $r[2]) if $r[2] < $r[0];
    ($r[3], $r[1]) = ($r[1], $r[3]) if $r[3] < $r[1];
    @r;
}

# Return azimuth (Richtungswinkel) of the given vector. Useful for
# angle arithmetic.
sub azimuth {
    my($ax,$ay,$bx,$by) = @_;
    atan2($by-$ay, $bx-$ax);
}

sub offset_line {
    my($pnts, $delta, $do_calc_right, $do_calc_left) = @_;

    my @offset_pnts_left;
    my @offset_pnts_right;

    my $before_azimuth = undef;
    my $after_azimuth;

    my $max_pnts_index = @$pnts/2-1;
    for my $p_i (0 .. $max_pnts_index) {
	my($p1x, $p1y) = @{$pnts}[$p_i*2, $p_i*2+1];
	my($p2x, $p2y) = $p_i < $max_pnts_index ? @{$pnts}[$p_i*2+2, $p_i*2+3] : (undef, undef);
	my $after_azimuth = defined $p2x ? azimuth($p1x,$p1y, $p2x,$p2y) : $before_azimuth;
	$before_azimuth = $after_azimuth if !defined $before_azimuth;

	my $angle = $after_azimuth-$before_azimuth;
	# normalize angle
	while ($angle <= -pi()) { $angle += pi*2 }
	while ($angle >   pi()) { $angle -= pi*2 }
	# # reliable detection of 180deg angle
	if ($p_i >= 1 && defined $p2x && $pnts->[$p_i*2-2] == $p2x && $pnts->[$p_i*2-1] == $p2y) {
	    $angle = -pi();
	}
	my $half_angle = $angle / 2;

	# used vars here: $p1, $before_azimuth
	my $offset_position = sub {
	    my($add_angle, $new_len) = @_;
	    my $angle = $before_azimuth + $add_angle;

	    my $len_angle_to_d = sub {
		my($len, $angle) = @_;
		my $xd = $len * cos($angle);
		my $yd = $len * sin($angle);
		($xd, $yd);
	    };

	    my($xd,$yd) = $len_angle_to_d->($new_len, $angle);
	    my($X2,$Y2) = ($p1x+$xd,$p1y+$yd);
	    ($X2,$Y2);
	};

	if ($do_calc_right) {
	    if ($angle < 0) {
		push @offset_pnts_right, ($offset_position->(-3/2*pi, $delta),
					  $offset_position->($half_angle - 3/2*pi, $delta),
					  $offset_position->($half_angle*2 - 3/2*pi, $delta));
	    } else {
		my $new_len = $delta / cos($half_angle);
		push @offset_pnts_right, $offset_position->($half_angle - 3/2*pi, $new_len);
	    }
	}

	if ($do_calc_left) {
	    if ($angle == -pi()) { # XXX What's the rationale for this corner case?
		push @offset_pnts_left, ($offset_position->(-pi()/2, $delta),
					 $offset_position->($half_angle - 3/2*pi, $delta),
					 $offset_position->($half_angle*2 - pi/2, $delta));
	    } elsif ($angle > 0) {
		push @offset_pnts_left, ($offset_position->(-pi()/2, $delta),
					 $offset_position->($half_angle - pi/2, $delta),
					 $offset_position->($half_angle*2 - pi/2, $delta));
	    } else {
		my $new_len = $delta / cos($half_angle);
		push @offset_pnts_left, $offset_position->($half_angle - pi/2, $new_len);
	    }
	}

	$before_azimuth = $after_azimuth;
    }

    (\@offset_pnts_right, \@offset_pnts_left);
}

# Return [$minx,$miny,$maxx,$maxy]
sub bbox_of_polygon {
    my($poly) = @_;
    my $minx = my $maxx = $poly->[0][0];
    my $miny = my $maxy = $poly->[0][1];
    for my $p (@$poly) {
	if ($p->[0] > $maxx) {
	    $maxx = $p->[0];
	} elsif ($p->[0] < $minx) {
	    $minx = $p->[0];
	}
	if ($p->[1] > $maxy) {
	    $maxy = $p->[1];
	} elsif ($p->[1] < $miny) {
	    $miny = $p->[1];
	}
    }
    [$minx,$miny,$maxx,$maxy];
}

sub combine_bboxes {
    my(@bboxes) = @_;
    return if !@bboxes;
    my($minx,$miny,$maxx,$maxy) = @{$bboxes[0]};
    for my $bbox (@bboxes) {
	if ($bbox->[2] > $maxx) {
	    $maxx = $bbox->[2];
	} elsif ($bbox->[0] < $minx) {
	    $minx = $bbox->[0];
	}
	if ($bbox->[3] > $maxy) {
	    $maxy = $bbox->[3];
	} elsif ($bbox->[1] < $miny) {
	    $miny = $bbox->[1];
	}
    }
    [$minx,$miny,$maxx,$maxy];
}

# from http://en.wikipedia.org/wiki/Triangle#Computing_the_area_of_a_triangle
# (shoelace formula)
# see also Strassen::Stat:area_for_coords for a general polygon area function
sub triangle_area {
    my(@p) = @_;
    0.5 * abs(($p[0][0]-$p[2][0])*($p[1][1]-$p[0][1]) - ($p[0][0]-$p[1][0])*($p[2][1]-$p[0][1]));
}

# from http://en.wikipedia.org/wiki/Triangle#Using_Heron.27s_formula
# (Heron's formula)
# note: for invalid lengths this function will fail --- and maybe may
# fail if supplied lengths are slightly inaccurate and would evaluate
# to a very small area
sub triangle_area_by_lengths {
    my($a, $b, $c) = @_;
    my $s = ($a + $b + $c) / 2;
    sqrt($s * ($s-$a) * ($s-$b) * ($s-$c));
}

# Protect from floating point inaccuracies
sub _pos_sqrt { $_[0] < 0 ? 0 : sqrt($_[0]) }

# REPO BEGIN
# REPO NAME sqr /home/e/eserte/src/repository 
# REPO MD5 846375a266b4452c6e0513991773b211
sub sqr { $_[0] * $_[0] }
# REPO END

# REPO BEGIN
# REPO NAME min /home/e/eserte/src/repository 
# REPO MD5 80379d2502de0283d7f02ef8b3ab91c2
BEGIN {
    if (eval { require List::Util; 1 }) {
	*min = \&List::Util::min;
    } else {
	*min = sub {
	    my $min = $_[0];
	    foreach (@_[1..$#_]) {
		$min = $_ if $_ < $min;
	    }
	    $min;
	};
    }
}
# REPO END

# REPO BEGIN
# REPO NAME max /home/e/eserte/src/repository 
# REPO MD5 6156c68fa67185196c12f0fde89c0f6b
BEGIN {
    if (eval { require List::Util; 1 }) {
	*max = \&List::Util::max;
    } else {
	*max = sub {
	    my $max = $_[0];
	    foreach (@_[1..$#_]) {
		$max = $_ if $_ > $max;
	    }
	    $max;
	};
    }
}
# REPO END

1;

__END__
