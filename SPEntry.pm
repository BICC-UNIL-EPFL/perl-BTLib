package SPdbref;
use strict;
use vars qw($VERSION);

$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    $self->{_DBRname} = undef;
    $self->{_DBRprim} = undef;
    $self->{_DBRsec} = undef;
    $self->{_DBRstat} = undef;
    $self->{_DBRnote} = undef;
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
#    warn "Destroying $self";
}

sub parse {
    my ($self, $strr) = @_;
    my ($prim, $sec, $stat, $note);
    my ($name) = $$strr =~ /^DR   ([-\w\/]+); /;
    $$strr =~ s/^DR   [-\w\/]+; //;
    if ($name eq "") {
	warn "Could not parse database reference:\n  $$strr\n";
	return;
    }
    if ($name =~ /^(EMBL|PROSITE)$/) {
	# These have three fields
	($prim, $sec, $stat, $note)
	    = $$strr =~ /^([^;]+); ([^;]+); ([^.]*)\.(.*)/;
	if ($prim eq "") {
	    # warn "Badly formatted $name reference:\n  $$strr\n";
	    ($prim, $stat, $note)
		= $$strr =~ /^([^;]+); ([^.]+)\.(.*)/;
	    $sec = $prim;
	    if ($prim eq "") {
		warn "Realy badly formatted $name reference!\n  $$strr\n";
	    }
	}
    } elsif ($name =~ /^UNIGENE/) {
	# This one has one field
	($prim, $note)
	    = $$strr =~ /^(\S+)\.(.*)/;
	if ($prim eq "") {
	    warn "Badly formatted $name reference:\n  $$strr\n";
	}
    } elsif ($name =~ /^INTERPRO/) {
	# This one has one or two fields
	($prim, $sec, $note)
	    = $$strr =~ /^([^;]+); ([^.]+)\.(.*)/;
	if ($prim eq "") {
	    ($prim, $note)
		= $$strr =~ /^(\S+)\.(.*)/;
	    $sec = "-";
	}
	if ($prim eq "") {
	    warn "Badly formatted $name reference:\n  $$strr\n";
	}
    } else {
	# The rest has two
	($prim, $sec, $note)
	    = $$strr =~ /^([^;]+); ([^.]+)\.(.*)/;
	if ($prim eq "") {
	    warn "Badly formatted $name reference:\n  $$strr\n";
	}
    }
    $self->{_DBRname} = $name;
    $self->{_DBRprim} = $prim;
    $self->{_DBRsec} = $sec;
    $self->{_DBRstat} = $stat;
    $self->{_DBRnote} = $note;
}

sub print {
    my ($self, $out) = @_;
    if ($self->{_DBRname} =~ /^(EMBL|PROSITE)$/) {
	if ($self->{_DBRstat} eq "") {
	    $self->{_DBRstat} = "-";
	}
	print $out "DR   $self->{_DBRname}; $self->{_DBRprim}; "
	    . "$self->{_DBRsec}; $self->{_DBRstat}.$self->{_DBRnote}\n";
    } elsif ($self->{_DBRname} =~ /^UNIGENE/) {
	print $out "DR   $self->{_DBRname}; $self->{_DBRprim}.$self->{_DBRnote}\n";
    } else {
	print $out "DR   $self->{_DBRname}; $self->{_DBRprim}; "
	    . "$self->{_DBRsec}.$self->{_DBRnote}\n";
    }
}

package SPEntry;

# We define an object that attempts to represent a SwissPROT entry.

use strict;
use vars qw($VERSION @ISA);
use BTLib;
use LitRef;

@ISA = qw(BTLib);
$VERSION = "0.23";

# Tweaking factor.
my $descrLineLen = 70;

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new();
    $self->{_SPname} = undef;
    $self->{_SPclass} = undef;
    $self->{_SPlen} = undef;
    $self->{_SPac} = [];
    $self->{_SPrev} = [];
    $self->{_SPdesc} = undef;
    $self->{_SPgene} = undef;
    $self->{_SPscn} = [];
    $self->{_SPcomn} = [];
    $self->{_SPog} = undef;
    $self->{_SPtaxo} = undef;
    $self->{_SPox} = undef;
    $self->{_SPlref} = undef;
    $self->{_SPcc} = [];
    $self->{_SPdbref} = [];
    $self->{_SPpe} = undef;
    $self->{_SPkw} = [];
    $self->{_SPft} = [];
    $self->{_SPmw} = undef;
    $self->{_SPcrc} = undef;
    $self->{_SPoh} = [];
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
}

sub de {
    my $self = shift;
    if (@_) {
	$self->{_SPdesc} = shift;
    }
    return $self->{_SPdesc};
}

sub firstAC {
    my $self = shift;
    return $ {$self->{_SPac}}[0];
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{_SPname} = shift;
    }
    return $self->{_SPname};
}

sub parse {
    my ($self, $strr) = @_;
    my @lines = split /\n/, $$strr;
    # Get the ID line.
    my $s = shift @lines;
    my ($n, $c, $l) = $s =~
	/^ID   (\S+)\s+([^;]+|PRELIMINARY;      PRT);\s+(\d+) AA\./;
    if ($n eq "") {
	warn "Could not parse SwissPROT entry:\n$$strr";
	return;
    }
    $self->{_SPname} = $n;
    $self->{_SPclass} = $c;
    $self->{_SPlen} = $l;
    my $dbid = "sp";
    my $dbSet = 0;
    if ($c eq "HYPOTHETICAL") {
	$dbid = "trg";
	$dbSet = 1;
    }
    while (defined ($_ = $lines[0])) {
	/^AC/ && do {
	    s/^AC//;
	    s/\s//g;
	    my @ac = split /;/, $_;
	    if ($#ac < 0) {
		warn "Bad AC line in:\n$$strr";
	    }
	    push @{$self->{_SPac}}, @ac;
	    shift @lines;
	    next;
	};
	/^DT/ && do {
	    s/^DT   //;
	    s/\s+$//;
	    if ($dbSet == 0) {
		if (/\sUniProtKB\/TrEMBL/) {
		    $dbid = "tr";
		    $dbSet = 1;
		} elsif (/\sUniProtKB\/Swiss-Prot/) {
		    $dbid = "sp";
		    $dbSet = 1;
		}
	    }
	    push @{$self->{_SPrev}}, $_;
	    shift @lines;
	    next;
	};
	/^DE/ && do {
	    s/^DE//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_SPdesc}) {
		$self->{_SPdesc} .= " $_";
	    } else {
		$self->{_SPdesc} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^GN/ && do {
	    s/^GN//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_SPgene}) {
		$self->{_SPgene} .= " $_";
	    } else {
		$self->{_SPgene} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^OS/ && do {
	    # Accumulate until trailing dot is seen, then parse.
	    s/^OS\s+//;
	    my $os = $_;
	    while ($lines[1] =~ s/^OS\s+//) {
		$os .= " " . $lines[1];
		shift @lines;
	    }
	    # Remove trailing dot
	    $os =~ s/\.$//;
	    # Split at the commas.
	    my @a = split /,/, $os;
	    foreach (@a) {
		s/^\s+//;
		s/^AND //;
		my $i = index $_, "(";
		if ($i >= 0) {
		    push @{$self->{_SPscn}}, substr($_, 0, $i - 1);
		    $_ = substr $_, $i + 1;
		    s/\)$//;
		    push @{$self->{_SPcomn}}, $_;
		} else {
		    push @{$self->{_SPscn}}, $_;
		    push @{$self->{_SPcomn}}, undef;
		}
	    }
	    shift @lines;
	    next;
	};
	/^OG/ && do {
	    # Could be analyzed similarly to OS.
	    s/^OG//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_SPog}) {
		$self->{_SPog} .= " $_";
	    } else {
		$self->{_SPog} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^OC/ && do {
	    s/^OC//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_SPtaxo}) {
		$self->{_SPtaxo} .= " $_";
	    } else {
		$self->{_SPtaxo} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^OX/ && do {
	    s/^OX\s+//;
	    s/\s+$//;
	    if (defined $self->{_SPox}) {
		$self->{_SPox} .= " $_";
	    } else {
		$self->{_SPox} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^OH/ && do {
	    s/^OH   //;
	    s/\s+$//;
	    push @{$self->{_SPoh}}, $_;
	    shift @lines;
	    next;
	};
	/^RN/ && do {
	    my $ref = LitRef->new;
	    $ref->parse(\@lines);
	    push @{$self->{_SPlref}}, $ref;
	    next;
	};
	/^CC/ && do {
	    s/^CC   //;
	    s/\s+$//;
	    push @{$self->{_SPcc}}, $_;
	    shift @lines;
	    next;
	};
	/^DR/ && do {
	    my $ref = SPdbref->new;
	    $ref->parse(\$lines[0]);
	    push @{$self->{_SPdbref}}, $ref;
	    shift @lines;
	    next;
	};
	/^PE/ && do {
	    s/^PE//;
	    s/^\s+//;
	    s/\s+$//;
	    $self->{_SPpe} = $_;
	    shift @lines;
	    next;
	};
	/^KW/ && do {
	    s/^KW//;
	    s/^\s+//;
	    s/\s+$//;
	    push @{$self->{_SPkw}}, $_;
	    shift @lines;
	    next;
	};
	/^FT/ && do {
	    s/^FT   //;
	    s/\s+$//;
	    push @{$self->{_SPft}}, $_;
	    shift @lines;
	    next;
	};
	/^SQ/ && do {
	    # Admit a word as last token, to be able to parse pir stuff.
	    # Might want to do something with it someday...
	    my ($l, $m, $c, $dummy) =
		/^SQ   SEQUENCE\s+(\d+) AA;\s+(\d*) MW;\s+(\w*) (\w+);/;
	    if ($l != $self->{_SPlen}) {
		warn "Bad length in sequence $self->{_SPname} header:\n $lines[0]\n";
		$self->{_SPlen} = $l; # Trust the second one...
	    }
	    $self->{_SPmw} = $m;
	    $self->{_SPcrc} = $c;
	    shift @lines;
	    my $seq = "";
	    while ($lines[0] =~ /^ /) {
		$seq .= $lines[0];
		shift @lines;
	    }
	    $self->seq($seq);
	    my $ac = $self->firstAC;
	    if ($self->{_SPclass} eq "PRELIMINARY") {
		# Get ac from EMBL link.
		foreach my $dr (@{$self->{_SPdbref}}) {
		    if ($dr->{_DBRname} eq "EMBL") {
			$ac = $dr->{_DBRprim};
			last;
		    }
		}
	    } elsif ($self->{_SPclass} eq "HYPOTHETICAL") {
		my $dr = $ {$self->{_SPdbref}}[0];
		$ac = $dr->{_DBRprim};
	    }
	    # Prepare some info about the gene.
	    my $gn;
	    my @G = $self->{_SPgene} =~ /Name=([^;]+);/g;
	    if ($#G >= 0) {
	      $gn = $G[0];
	      $gn .= ".." if $#G > 0;
	    } else {
	      $gn = $self->{_SPgene};
	      if ($gn =~ /\s/) {
		  $gn =~ s/^(\S+).*/$1/;
		  $gn =~ s/^\(+//;
		  $gn .= "..";
	      } else {
		  $gn =~ s/\.$//;
	      }
	    }
	    if ($gn ne "") {
		$gn = "($gn)";
	    }
	    my $os = $ {$self->{_SPscn}}[0];
	    $os = "[$os]";
	    if ($dbid eq "trg") {
		$self->seqHead(">$dbid|$self->{_SPname}|$ac $os$gn$self->{_SPdesc}");
	    } else {
		$self->seqHead(">$dbid|$ac|$self->{_SPname} $gn$self->{_SPdesc}$os");
	    }
	    next;
	};
	m"^//" && last;
	warn "Unknown line: $_\n";
	shift @lines;
    }
}

sub printSplit {
    my ($out, $tag, $s, $term) = @_;
    while (length $s > $descrLineLen
	   && !(substr($s, $descrLineLen) =~ /^[.;]$/)) {
	my $pos = rindex $s, " ", $descrLineLen;
	if ($pos == -1) {
	    $pos = index $s, " ";
	    if ($pos == -1) {
		$pos = length $s;
	    }
	}
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "$tag   $ss\n";
    }
    print $out "$tag   $s$term\n";
}

sub printSP {
    my ($self, $out) = @_;
    print $out "ID   $self->{_SPname}";
    print $out " "x(24 - length($self->{_SPname}));
    print $out "$self->{_SPclass};";
    print $out " "x(14 - length($self->{_SPclass}));
    printf $out "%6d AA.\n", $self->{_SPlen};
    printSplit($out, "AC", join("; ", @{$self->{_SPac}}), ";");
    foreach (@{$self->{_SPrev}}) {
	print $out "DT   $_\n";
    }
    printSplit($out, "DE", $self->{_SPdesc}, "");
    if (defined $self->{_SPgene}) {
	printSplit($out, "GN", $self->{_SPgene}, "");
    }
    my $l = $#{$self->{_SPscn}};
    my $s = "";
    for (my $count = 0; $count <= $l; $count++) {
	my $scn = $ {$self->{_SPscn}}[$count];
	my $comn = $ {$self->{_SPcomn}}[$count];
	if (defined $comn) {
	    $scn .= " ($comn)";
	}
	if ($count == 0) {
	    $s = $scn;
	} elsif ($count == $l) {
	    $s .= ", AND $scn";
	} else {
	    $s .= ", $scn";
	}
    }
    printSplit($out, "OS", $s, ".");
    if (defined $self->{_SPog}) {
	printSplit($out, "OG", $self->{_SPog}, "");
    }
    printSplit($out, "OC", $self->{_SPtaxo}, "");
    if (defined $self->{_SPox}) {
	printSplit($out, "OX", $self->{_SPox}, "");
    }
    foreach (@{$self->{_SPoh}}) {
	print $out "OH   $_\n";
    }
    foreach my $ref (@{$self->{_SPlref}}) {
	$ref->print($out, $descrLineLen);
    }
    foreach (@{$self->{_SPcc}}) {
	print $out "CC   $_\n";
    }
    foreach my $ref (@{$self->{_SPdbref}}) {
	$ref->print($out);
    }
    if (defined $self->{_SPpe}) {
	print $out "PE   ", $self->{_SPpe}, "\n";
    }
    foreach (@{$self->{_SPkw}}) {
	print $out "KW   $_\n";
    }
    foreach (@{$self->{_SPft}}) {
	print $out "FT   $_\n";
    }
    print $out "SQ   SEQUENCE   $self->{_SPlen} AA;  $self->{_SPmw} MW;  "
	. "$self->{_SPcrc} CRC64;\n";
    $l = length $self->{_seq};
    for (my $pos = 0; $pos < $l; $pos += 60) {
	$s = substr $self->{_seq}, $pos, 60;
	$s =~ s/(.{10})/$1 /g;
	$s =~ s/ $//;
	print $out "     $s\n";
    }
    print $out "//\n";
}

sub osMatch {
    my ($self, $scn, $comn) = @_;
    my $i;
    $scn = lc $scn;
    $comn = lc $comn;
    $scn =~ s/\W//g;
    $comn =~ s/\W//g;
    for ($i = 0; $i <= $#{$self->{_SPscn}}; $i++) {
	my $s = $ {$self->{_SPscn}}[$i];
	my $c = $ {$self->{_SPcomn}}[$i];
	$s = lc $s;
	$c = lc $c;
	$s =~ s/\W//g;
	$c =~ s/\W//g;
	if (($comn ne "") && ($c ne "")) {
	    return 1 if ($scn eq $s) && ($comn eq $c);
	} else {
	    return 1 if ($scn eq $s);
	}
    }
    return 0;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
