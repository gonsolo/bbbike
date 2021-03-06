# DO NOT EDIT! Generated by Generated_src.pm!

package Strassen::Generated;

package StrassenNetz;

require Strassen::Util; # XXX move to subs

sub make_net_slow_1 {
    my($self, %args) = @_;

    my $cacheable = defined $args{UseCache} ? $args{UseCache} : $Strassen::Util::cacheable;
    if ($cacheable) {
        return if $self->net_read_cache_1;
    }

    $self->{strecke_sub}   = \&Strassen::Util::strecke;
    $self->{strecke_s_sub} = \&Strassen::Util::strecke_s;
    $self->{to_koord_sub}  = \&Strassen::to_koord;
    if ($self->{Strassen}{GlobalDirectives} && $self->{Strassen}{GlobalDirectives}{map} && $self->{Strassen}{GlobalDirectives}{map}[0] eq 'polar') {
        $self->{strecke_sub}   = \&Strassen::Util::strecke_polar;
	$self->{strecke_s_sub} = \&Strassen::Util::strecke_s_polar;
        $self->{to_koord_sub}  = \&Strassen::to_koord_f;
    }
    local *strecke = $self->{strecke_sub};
    local *to_koord = $self->{to_koord_sub};

    if ($VERBOSE) {
	warn "Using slow (type 1) version of make_net\n";
    }

    $self->{Net2Name}    = {}; # Zuordnung Strecke => Stra�enname
    $self->{Net}         = {}; # Verbindungsnetz
    my $net2name = $self->{Net2Name};

    $self->{Wegfuehrung} = {}; # unerlaubte Wegf�hrung
    $self->{Penalty}     = {}; # zus�tzliche Penalties
    my $net      = $self->{Net};
    my $strassen = $self->{Strassen};
    $strassen->init;
    while(1) {
	my $ret = $strassen->next;
	my @kreuzungen = @{$ret->[Strassen::COORDS()]};
	last if @kreuzungen == 0;
	my @kreuz_coord = @{to_koord(\@kreuzungen)};


	for(my $i = 0; $i < $#kreuzungen; $i++) {
	    # Integer reicht vollkommen aus, da die Angaben sowieso in m sind
	    my $entf = int(strecke($kreuz_coord[$i], $kreuz_coord[$i+1]));
 	    $net->{$kreuzungen[$i]}{$kreuzungen[$i+1]} = $entf;
 	    $net->{$kreuzungen[$i+1]}{$kreuzungen[$i]} = $entf;
# XXX not yet, but maybe someday necessary:
#  	    if (exists $net2name->{$kreuzungen[$i]}{$kreuzungen[$i+1]}) {
#  		if (ref $net2name->{$kreuzungen[$i]}{$kreuzungen[$i+1]} ne 'ARRAY') {
#  		    $net2name->{$kreuzungen[$i]}{$kreuzungen[$i+1]} = [ $net2name->{$kreuzungen[$i]}{$kreuzungen[$i+1]} ];
#  		}
#  		push @{ $net2name->{$kreuzungen[$i]}{$kreuzungen[$i+1]} }, $strassen->pos;
#  	    } else {
		$net2name->{$kreuzungen[$i]}{$kreuzungen[$i+1]} = $strassen->pos;
#	    }
	}

    }

    if ($cacheable) {
	$self->net_write_cache_1;
    }

    $self->{UseMLDBM} = 0;
}

sub net_read_cache_1 {
    my($self) = @_;
    my @src = $self->dependent_files;
    if (!@src || grep { !defined $_ } @src) {
	return 0;
    }
    my $cachefile = $self->get_cachefile;

    my $net2name = Strassen::Util::get_from_cache("net2name_1_$cachefile", \@src);

    my $net = Strassen::Util::get_from_cache("net_1_$cachefile", \@src);
    if (

	defined $net2name &&

	defined $net
       ) {

	$self->{Net2Name} = $net2name;

	$self->{Net} = $net;
	if ($VERBOSE) {
	    warn "Using cache for $cachefile\n";
	}
	return 1;
    } else {
	return 0;
    }
}

sub net_write_cache_1 {
    my($self) = @_;
    my @src = $self->dependent_files;
    if (!@src || grep { !defined $_ } @src) {
	return;
    }
    my $cachefile = $self->get_cachefile;

    Strassen::Util::write_cache($self->{Net2Name}, "net2name_1_$cachefile", -modifiable => 1);

    Strassen::Util::write_cache($self->{Net}, "net_1_$cachefile", -modifiable => 1);
    if ($VERBOSE) {
        warn "Wrote cache ($cachefile)\n";
    }
}

sub make_net_slow_2 {
    my($self, %args) = @_;

    my $cacheable = defined $args{UseCache} ? $args{UseCache} : $Strassen::Util::cacheable;
    if ($cacheable) {
        return if $self->net_read_cache_2;
    }

    $self->{strecke_sub}   = \&Strassen::Util::strecke;
    $self->{strecke_s_sub} = \&Strassen::Util::strecke_s;
    $self->{to_koord_sub}  = \&Strassen::to_koord;
    if ($self->{Strassen}{GlobalDirectives} && $self->{Strassen}{GlobalDirectives}{map} && $self->{Strassen}{GlobalDirectives}{map}[0] eq 'polar') {
        $self->{strecke_sub}   = \&Strassen::Util::strecke_polar;
	$self->{strecke_s_sub} = \&Strassen::Util::strecke_s_polar;
        $self->{to_koord_sub}  = \&Strassen::to_koord_f;
    }
    local *strecke = $self->{strecke_sub};
    local *to_koord = $self->{to_koord_sub};

    if ($VERBOSE) {
	warn "Using slow (type 2) version of make_net\n";
    }

    $self->{Index2Pos}   = []; # Zuordnung Index-Paar => Pos im Stra�enfile
    $self->{Coord2Index} = {}; # Zuordnung Koordinate => Index
    $self->{Index2Coord} = []; # Zuordnung Index => Koordinate
    $self->{Net}         = []; # Verbindungsnetz
    my $index2pos   = $self->{Index2Pos};
    my $coord2index = $self->{Coord2Index};
    my $index2coord = $self->{Index2Coord};
    my $pos = 0;

    $self->{Wegfuehrung} = {}; # unerlaubte Wegf�hrung
    $self->{Penalty}     = {}; # zus�tzliche Penalties
    my $net      = $self->{Net};
    my $strassen = $self->{Strassen};
    $strassen->init;
    while(1) {
	my $ret = $strassen->next;
	my @kreuzungen = @{$ret->[Strassen::COORDS()]};
	last if @kreuzungen == 0;
	my @kreuz_coord = @{to_koord(\@kreuzungen)};


	my @k_i;
	foreach my $cp (@kreuz_coord) {
	    my $c = pack("l2", @$cp);
	    if (!exists $coord2index->{$c}) {
		$coord2index->{$c} = pack("l", $pos);
		$index2coord->[$pos] = $c;
		$pos++;
	    }
	    push @k_i, $coord2index->{$c};
	}

	for (my $i = 0; $i < $#k_i; $i++) {
	    my $entf = pack("l",
			    int(strecke($kreuz_coord[$i], $kreuz_coord[$i+1])));
	    my $k_i_u  = unpack("l", $k_i[$i]);
	    my $k_i1_u = unpack("l", $k_i[$i+1]);
	    $net->[$k_i_u]  .= $k_i[$i+1] . $entf;
	    $net->[$k_i1_u] .= $k_i[$i]   . $entf;
	    $index2pos->[$k_i_u]  .= $k_i[$i+1] . pack("l", $strassen->pos);
	    $index2pos->[$k_i1_u] .= $k_i[$i]   . pack("l", $strassen->pos);
	}

    }

    if ($cacheable) {
	$self->net_write_cache_2;
    }

    $self->{UseMLDBM} = 0;
}

sub net_read_cache_2 {
    my($self) = @_;
    my @src = $self->dependent_files;
    if (!@src || grep { !defined $_ } @src) {
	return 0;
    }
    my $cachefile = $self->get_cachefile;

    my $coord2index = Strassen::Util::get_from_cache("coord2index_2_$cachefile", \@src);
    my $index2coord = Strassen::Util::get_from_cache("index2coord_2_$cachefile", \@src);
    my $index2pos   = Strassen::Util::get_from_cache("index2pos_2_$cachefile", \@src);

    my $net = Strassen::Util::get_from_cache("net_2_$cachefile", \@src);
    if (

	defined $coord2index &&
	defined $index2coord &&
	defined $index2pos &&

	defined $net
       ) {

	$self->{Coord2Index} = $coord2index;
	$self->{Index2Coord} = $index2coord;
	$self->{Index2Pos}   = $index2pos;

	$self->{Net} = $net;
	if ($VERBOSE) {
	    warn "Using cache for $cachefile\n";
	}
	return 1;
    } else {
	return 0;
    }
}

sub net_write_cache_2 {
    my($self) = @_;
    my @src = $self->dependent_files;
    if (!@src || grep { !defined $_ } @src) {
	return;
    }
    my $cachefile = $self->get_cachefile;

    Strassen::Util::write_cache($self->{Coord2Index}, "coord2index_2_$cachefile");
    Strassen::Util::write_cache($self->{Index2Coord}, "index2coord_2_$cachefile");
    Strassen::Util::write_cache($self->{Index2Pos}, "index2pos_2_$cachefile");

    Strassen::Util::write_cache($self->{Net}, "net_2_$cachefile", -modifiable => 1);
    if ($VERBOSE) {
        warn "Wrote cache ($cachefile)\n";
    }
}

sub route_to_name_1 {
    my($self, $route_ref, %args) = @_;
    my @strname;
    my $start_i = defined $args{'-startindex'} ? $args{'-startindex'} : 0;
    my $combinestreet = defined $args{'-combinestreet'} ? $args{'-combinestreet'} : 1;
    require Route;
    require Strassen::Util;
    require Strassen::Strasse;
    local *strecke = $self->{strecke_sub} || \&Strassen::Util::strecke;
    my $i;
    for($i = 0; $i < $#{$route_ref}; $i++) {

	my $xy1 = Route::_coord_as_string([$route_ref->[$i][0],
					   $route_ref->[$i][1]]);
	my $xy2 = Route::_coord_as_string([$route_ref->[$i+1][0],
					   $route_ref->[$i+1][1]]);
	my($str_i, $rueckwaerts) = $self->net2name($xy1, $xy2);
	my $entf = $self->{Net}{$xy1}{$xy2};

	# May happen if two same points follow subsequently in the route.
	next if defined $entf && $entf == 0;
	# May happen for inserted or moved points which are not anymore in the net.
	if (!defined $entf) {
	    $entf = strecke([split /,/, $xy1], [split /,/, $xy2]);
	}
	my $str;
	if (!defined $str_i) {
	    ($str_i, $rueckwaerts) = $self->nearest_street($xy1, $xy2);
	}
	if (defined $str_i) {
	    if ($str_i =~ /^\d/) {
		$str = $self->{Strassen}->get($str_i)->[0];
		$str = Strasse::beautify_landstrasse($str, $rueckwaerts);
	    } else {
		$str = $str_i;
	    }
	} else {
	    # Aha. Wir haben hier wahrscheinlich einen angeklickten
	    # Punkt zwischen zwei Kurvenpunkten, der nicht mehr durch
	    # add_net abgedeckt ist. Also wird einfach geraten, ob der
	    # Punkt zur vorherigen Strecke geh�rt, indem der Schnittwinkel
	    # �berpr�ft wird.
	    # Der Algorithmus ist nicht perfekt, weil einige Schnittwinkel
	    # im 90�-Bereich liegen, wo es sich trotzdem um die gleiche
	    # Stra�e handelt. Naja.
	    if ($i+1 < $#{$route_ref}) {
		my($w) = schnittwinkel
		  (split(/,/,$xy1),
		   split(/,/,$xy2),
		   split(/,/,Route::_coord_as_string
			 ([$route_ref->[$i+2][0],
			   $route_ref->[$i+2][1]])));
		if ($w < 0.15 || $w > 3.00) {
		    # ca. 10� Abweichung von der Geraden werden toleriert
		    $str = ($#strname >= 0 ? $strname[$#strname]->[0] : '???');
		}
	    }
	    # (Garantiert) unbekannte Stra�e.
	    if (!defined $str) {
		$str = "...";
	    }
	}
	my($winkel, $richtung);
	if ($i+1 < $#{$route_ref}) {
	    ($richtung, $winkel) = Strassen::Util::abbiegen(@{$route_ref}[$i .. $i+2]);
	    # This usually happens if either first and second or second and third
	    # points are the same. Make sure that no warnings happen. But it would
	    # be better if the caller made sure that this never happens...
	    if (!defined $winkel) {
		($richtung, $winkel) = ('', 0);
	    }
	}
	my $extra;
	if (@strname &&
	    ($combinestreet && $str eq $strname[$#strname]->[ROUTE_NAME] &&
	     !($strname[$#strname]->[ROUTE_EXTRA] && $strname[$#strname]->[ROUTE_EXTRA]{ImportantAngle}))) {
	    $strname[$#strname][ROUTE_DIST] += $entf;
	    $strname[$#strname][ROUTE_ANGLE] = $winkel;
	    $strname[$#strname][ROUTE_DIR] = $richtung;
	    $strname[$#strname][ROUTE_ARRAYINX][1] = $i+$start_i;
	    $extra = $strname[$#strname][ROUTE_EXTRA];
	    if ($extra) {
		if ($args{-wanttrafficlights}) {
		    $extra->{Trafficlights} = +0;
		    $extra->{TrafficlightAtPoint} = 0;
		}
	    }
	} else {
	    my $val = [];
	    $val->[ROUTE_NAME]	 = $str;
	    $val->[ROUTE_DIST]	 = $entf;
	    $val->[ROUTE_ANGLE]	 = $winkel;
	    $val->[ROUTE_DIR]	 = $richtung;
	    $val->[ROUTE_ARRAYINX] = [$i+$start_i, $i+$start_i];
	    $extra = $val->[ROUTE_EXTRA] = {};
	    if ($args{-wanttrafficlights}) {
		$extra->{Trafficlights} = 0;
		$extra->{TrafficlightAtPoint} = 0;
	    }
	    push @strname, $val;
	}


	if ($i+1 < $#{$route_ref}) {
	    my $xy3 = Route::_coord_as_string([$route_ref->[$i+2][0],
				               $route_ref->[$i+2][1]]);
	    for my $neighbour (keys %{$self->{Net}{$xy2}}) {
		next if $neighbour eq $xy1 || $neighbour eq $xy3;
		my($this_richtung, $this_winkel) = Strassen::Util::abbiegen(@{$route_ref}[$i .. $i+1],
									    [split/,/,$neighbour]);
		next if !defined $this_winkel;
		next if ($this_richtung ne $richtung && $this_winkel >= 30);
		next if $winkel < $this_winkel;
		$extra->{ImportantAngle} = '!';
		{
		    my($str_i, $rueckwaerts) = $self->net2name($xy2, $neighbour);
		    if (defined $str_i) {
			my $str = $self->{Strassen}->get($str_i)->[0];
			$str = Strasse::beautify_landstrasse($str, $rueckwaerts);
			$extra->{ImportantAngleCrossingName} = $str;
		    }
		}
		last;
	    }
	}


    }

    @strname;
}
sub route_to_name_2 {
    my($self, $route_ref, %args) = @_;
    my @strname;
    my $start_i = defined $args{'-startindex'} ? $args{'-startindex'} : 0;
    my $combinestreet = defined $args{'-combinestreet'} ? $args{'-combinestreet'} : 1;
    require Route;
    require Strassen::Util;
    require Strassen::Strasse;
    local *strecke = $self->{strecke_sub} || \&Strassen::Util::strecke;
    my $i;
    for($i = 0; $i < $#{$route_ref}; $i++) {

	my $xy1 = $self->{Coord2Index}->
	  {pack("l2", $route_ref->[$i][0], $route_ref->[$i][1])};
	my $xy1_u = unpack("l", $xy1);
	my $xy2 = $self->{Coord2Index}->
	  {pack("l2", $route_ref->[$i+1][0], $route_ref->[$i+1][1])};
	my $str_i;
	my $rueckwaerts = 0; # XXX
	my $entf;
	{
	    # first find pos of neighbor
	    my $net_s = $self->{Index2Pos}[$xy1_u];
	    my $net_s_len = length($net_s);
	    for(my $i = 0; $i < $net_s_len; $i+=8) {
		if (substr($net_s, $i, 4) eq $xy2) {
		    $str_i = unpack("l", substr($net_s, $i+4, 4));
		    last;
		}
	    }
	    # then find distance to neighbor
	    $net_s = $self->{Net}[$xy1_u];
	    $net_s_len = length($net_s);
	    for(my $i = 0; $i < $net_s_len; $i+=8) {
		if (substr($net_s, $i, 4) eq $xy2) {
		    $entf = unpack("l", substr($net_s, $i+4, 4));
		    last;
		}
	    }
	}

	# May happen if two same points follow subsequently in the route.
	next if defined $entf && $entf == 0;
	# May happen for inserted or moved points which are not anymore in the net.
	if (!defined $entf) {
	    $entf = strecke([split /,/, $xy1], [split /,/, $xy2]);
	}
	my $str;
	if (!defined $str_i) {
	    ($str_i, $rueckwaerts) = $self->nearest_street($xy1, $xy2);
	}
	if (defined $str_i) {
	    if ($str_i =~ /^\d/) {
		$str = $self->{Strassen}->get($str_i)->[0];
		$str = Strasse::beautify_landstrasse($str, $rueckwaerts);
	    } else {
		$str = $str_i;
	    }
	} else {
	    # Aha. Wir haben hier wahrscheinlich einen angeklickten
	    # Punkt zwischen zwei Kurvenpunkten, der nicht mehr durch
	    # add_net abgedeckt ist. Also wird einfach geraten, ob der
	    # Punkt zur vorherigen Strecke geh�rt, indem der Schnittwinkel
	    # �berpr�ft wird.
	    # Der Algorithmus ist nicht perfekt, weil einige Schnittwinkel
	    # im 90�-Bereich liegen, wo es sich trotzdem um die gleiche
	    # Stra�e handelt. Naja.
	    if ($i+1 < $#{$route_ref}) {
		my($w) = schnittwinkel
		  (split(/,/,$xy1),
		   split(/,/,$xy2),
		   split(/,/,Route::_coord_as_string
			 ([$route_ref->[$i+2][0],
			   $route_ref->[$i+2][1]])));
		if ($w < 0.15 || $w > 3.00) {
		    # ca. 10� Abweichung von der Geraden werden toleriert
		    $str = ($#strname >= 0 ? $strname[$#strname]->[0] : '???');
		}
	    }
	    # (Garantiert) unbekannte Stra�e.
	    if (!defined $str) {
		$str = "...";
	    }
	}
	my($winkel, $richtung);
	if ($i+1 < $#{$route_ref}) {
	    ($richtung, $winkel) = Strassen::Util::abbiegen(@{$route_ref}[$i .. $i+2]);
	    # This usually happens if either first and second or second and third
	    # points are the same. Make sure that no warnings happen. But it would
	    # be better if the caller made sure that this never happens...
	    if (!defined $winkel) {
		($richtung, $winkel) = ('', 0);
	    }
	}
	my $extra;
	if (@strname &&
	    ($combinestreet && $str eq $strname[$#strname]->[ROUTE_NAME] &&
	     !($strname[$#strname]->[ROUTE_EXTRA] && $strname[$#strname]->[ROUTE_EXTRA]{ImportantAngle}))) {
	    $strname[$#strname][ROUTE_DIST] += $entf;
	    $strname[$#strname][ROUTE_ANGLE] = $winkel;
	    $strname[$#strname][ROUTE_DIR] = $richtung;
	    $strname[$#strname][ROUTE_ARRAYINX][1] = $i+$start_i;
	    $extra = $strname[$#strname][ROUTE_EXTRA];
	    if ($extra) {
		if ($args{-wanttrafficlights}) {
		    $extra->{Trafficlights} = +0;
		    $extra->{TrafficlightAtPoint} = 0;
		}
	    }
	} else {
	    my $val = [];
	    $val->[ROUTE_NAME]	 = $str;
	    $val->[ROUTE_DIST]	 = $entf;
	    $val->[ROUTE_ANGLE]	 = $winkel;
	    $val->[ROUTE_DIR]	 = $richtung;
	    $val->[ROUTE_ARRAYINX] = [$i+$start_i, $i+$start_i];
	    $extra = $val->[ROUTE_EXTRA] = {};
	    if ($args{-wanttrafficlights}) {
		$extra->{Trafficlights} = 0;
		$extra->{TrafficlightAtPoint} = 0;
	    }
	    push @strname, $val;
	}


	warn "Cannot determine ImportantAngle with this format!";


    }

    @strname;
}
sub reachable_1 {
    my($self, $coord) = @_;
    if (!exists $self->{Net}{$coord}) {
	warn "Die Koordinate $coord kann im Netz nicht erreicht werden\n"
	  if $VERBOSE;
	0;
    } else {
	1;
    }
}
sub reachable_2 {
    my($self, $coord) = @_;
    if (!defined $self->{Net}[$self->{Coord2Index}{$coord}]) {
	warn "Die Koordinate $coord kann im Netz nicht erreicht werden\n"
	  if $VERBOSE;
	0;
    } else {
	1;
    }
}

1;
