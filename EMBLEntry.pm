package EMBLdbref;
use strict;
use vars qw($VERSION);

$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    $self->{_DBRname} = undef;
    $self->{_DBRac} = undef;
    $self->{_DBRid} = undef;
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
    my ($ac, $id, $note);
    my ($name) = $$strr =~ /^DR   ([-\w\/]+); /;
    $$strr =~ s/^DR   [-\w\/]+; //;
    if ($name eq "") {
	warn "Could not parse database reference:\n  $$strr\n";
	return;
    }
  SWITCH:
    for ($name) {
	/^(SWISS-PROT|SPTREMBL|EMBL)$/ && do {
	    ($ac, $id, $note)
		= $$strr =~ /^(\S+); (\w+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted $name reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	m,^IMGT/$, && do {
	    ($ac, $id, $note)
		= $$strr =~ /^(\w+); ([\w*]+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted $name reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	# warn "Unknown database reference: $name $$strr\n";
	$note = $$strr;
    }
    $self->{_DBRname} = $name;
    $self->{_DBRac} = $ac;
    $self->{_DBRid} = $id;
    $self->{_DBRnote} = $note;
}

sub print {
    my ($self, $out) = @_;
  SWITCH:
    for ($self->{_DBRname}) {
	/^(SWISS-PROT|SPTREMBL|EMBL)$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}; "
		. "$self->{_DBRid}.$self->{_DBRnote}\n";
	    last SWITCH;
	};
	m,^IMGT/$, && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}; "
		. "$self->{_DBRid}.$self->{_DBRnote}\n";
	    last SWITCH;
	};
	# warn "Unknown database format $self->{_DBRname}\n";
	print $out "DR   $self->{_DBRname}; $self->{_DBRnote}\n";
    }
}

package EMBLEntry;

# We define an object that attempts to represent an EMBL entry.

use strict;
use vars qw($VERSION @ISA);
use BTLib;
use LitRef;

@ISA = qw(BTLib);
$VERSION = "0.23";

# Tweaking factor.
my $descrLineLen = 74;

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new();
    $self->{_EMBLsvnb} = undef;
    $self->{_EMBLtype} = undef;
    $self->{_EMBLtopology} = undef;
    $self->{_EMBLdivision} = undef;
    $self->{_EMBLclass} = undef;
    $self->{_EMBLlen} = undef;
    $self->{_EMBLac} = [];
    $self->{_EMBLni} = undef;
    $self->{_EMBLsv} = undef;
    $self->{_EMBLkw} = [];
    $self->{_EMBLrev} = [];
    $self->{_EMBLdesc} = undef;
    $self->{_EMBLscn} = [];
    $self->{_EMBLcomn} = [];
    $self->{_EMBLdbref} = [];
    $self->{_EMBLlref} = undef;
    $self->{_EMBLtaxo} = undef;
    $self->{_EMBLog} = undef;
    $self->{_EMBLcc} = [];
    $self->{_EMBLas} = [];
    $self->{_EMBLft} = [];
    $self->{_EMBLcnta} = undef;
    $self->{_EMBLcntc} = undef;
    $self->{_EMBLcntg} = undef;
    $self->{_EMBLcntt} = undef;
    $self->{_EMBLcnto} = undef;
    $self->{_EMBLconstruct} = undef;
    $self->{_EMBLproject} = undef;
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
	$self->{_EMBLdesc} = shift;
    }
    return $self->{_EMBLdesc};
}

sub firstAC {
    my $self = shift;
    return $ {$self->{_EMBLac}}[0];
}

sub ac {
    my $self = shift;
    return $ {$self->{_EMBLac}}[0];
}

sub EMBLtype {
    my $self = shift;
    if (@_) {
	$self->{_EMBLtype} = shift;
    }
    return $self->{_EMBLtype};
}

sub ni {
    my $self = shift;
    if (@_) {
	$self->{_EMBLni} = shift;
    }
    return $self->{_EMBLni};
}

sub sv {
    my $self = shift;
    if (@_) {
	$self->{_EMBLsv} = shift;
    }
    return $self->{_EMBLsv};
}

sub parse {
    my ($self, $strr) = @_;
    my @lines = split /\n/, $$strr;
    # Get the ID line.
    my $s = shift @lines;
    my ($ac, $sv, $topo, $t, $c, $d, $l) = $s =~
	/^ID   ([^;]+); SV ([^;]+); ([^;]+); ([^;]+); ([^;]+); ([^;]+); (\d+) BP\./;
    if ($ac eq "") {
	warn "Could not parse EMBL entry:\n$$strr";
	return;
    }
    $ {$self->{_EMBLac}}[0] = $ac;
    $self->{_EMBLsvnb} = $sv;
    $self->{_EMBLsv} = "$ac.$sv";
    $self->{_EMBLtopology} = $topo;
    $self->{_EMBLtype} = $t;
    $self->{_EMBLclass} = $c;
    $self->{_EMBLdivision} = $d;
    $self->{_EMBLlen} = $l;
    while (defined ($_ = $lines[0])) {
	/^(XX|AH|FH)/ && do {
	    shift @lines;
	    next;
	};
	/^AC/ && do {
	    s/^AC//;
	    s/\s//g;
	    my @A = split /;/, $_;
	    foreach my $a (@A) {
	      next if $a eq $ac;
	      push @{$self->{_EMBLac}}, $a;
	    }
	    shift @lines;
	    next;
	};
	/^NI/ && do {
	    s/^NI//;
	    s/^\s+//;
	    s/\s+$//;
	    $self->{_EMBLni} = $_;
	    shift @lines;
	    next;
	};
	/^PR/ && do {
	    s/^PR//;
	    s/^\s+//;
	    s/\s+$//;
	    $self->{_EMBLproject} = $_;
	    shift @lines;
	    next;
	};
	/^DT/ && do {
	    s/^DT   //;
	    s/\s+$//;
	    push @{$self->{_EMBLrev}}, $_;
	    shift @lines;
	    next;
	};
	/^DE/ && do {
	    s/^DE//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_EMBLdesc}) {
		$self->{_EMBLdesc} .= " $_";
	    } else {
		$self->{_EMBLdesc} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^KW/ && do {
	    s/^KW//;
	    s/^\s+//;
	    s/\s+$//;
	    push @{$self->{_EMBLkw}}, $_;
	    shift @lines;
	    next;
	};
	/^OS/ && do {
	    my ($sn, $com);
	    if (/^OS   (.+)\(([^(]+)\)\s*$/) {
		$sn = $1;
		$com = $2;
	    } else {
		s/^OS//;
		s/^\s+//;
		$sn = $_;
	    }
	    $sn =~ s/\s+$//;
	    push @{$self->{_EMBLscn}}, $sn;
	    push @{$self->{_EMBLcomn}}, $com;
	    shift @lines;
	    next;
	};
	/^OC/ && do {
	    s/^OC//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_EMBLtaxo}) {
		$self->{_EMBLtaxo} .= " $_";
	    } else {
		$self->{_EMBLtaxo} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^OG/ && do {
	    s/^OG//;
	    s/^\s+//;
	    s/\s+$//;
	    $self->{_EMBLog} = $_;
	    shift @lines;
	    next;
	};
	/^DR/ && do {
	    my $ref = EMBLdbref->new;
	    $ref->parse(\$lines[0]);
	    push @{$self->{_EMBLdbref}}, $ref;
	    shift @lines;
	    next;
	};
	/^RN/ && do {
	    my $ref = LitRef->new;
	    $ref->parse(\@lines);
	    push @{$self->{_EMBLlref}}, $ref;
	    next;
	};
	/^CC/ && do {
	    s/^CC//;
	    s/^\s+//;
	    s/\s+$//;
	    push @{$self->{_EMBLcc}}, $_;
	    shift @lines;
	    next;
	};
	/^AS/ && do {
	    s/^AS   //;
	    s/\s+$//;
	    push @{$self->{_EMBLas}}, $_;
	    shift @lines;
	    next;
	};
	/^FT/ && do {
	    s/^FT   //;
	    s/\s+$//;
	    push @{$self->{_EMBLft}}, $_;
	    shift @lines;
	    next;
	};
	/^SQ/ && do {
	    my ($l, $a, $c, $g, $t, $o) =
		/^SQ   Sequence\s+(\d*) BP;\s*(\d*) A;\s*(\d*) C;\s*(\d*) G;\s*(\d*) T;\s*(\d*) other/;
	    if ($l != $self->{_EMBLlen}) {
		warn "Bad length in sequence header ($self->{_EMBLlen}):\n"
		  . "$lines[0]\n";
	    }
	    if ($a + $c + $g + $t + $o != $l) {
		warn "Length does not compute in sequence header:\n $lines[0]\n";
	    }
	    $self->{_EMBLcnta} = $a;
	    $self->{_EMBLcntc} = $c;
	    $self->{_EMBLcntg} = $g;
	    $self->{_EMBLcntt} = $t;
	    $self->{_EMBLcnto} = $o;
	    shift @lines;
	    my $seq = "";
	    while ($lines[0] =~ /^ /) {
		$seq .= $lines[0];
		shift @lines;
	    }
	    $self->seq($seq);
	    $self->seqHead(">emb|$ac|$ac.$sv ["
			   . $ {$self->{_EMBLscn}}[0] . "]$self->{_EMBLdesc}");
	    next;
	};
	/^CO/ && do {
	    s/^CO\s+//;
	    s/\s+$//;
	    $self->{_EMBLconstruct} = $_;
	    shift @lines;
	    while ($lines[0] =~ /^CO/) {
	      $lines[0] =~ s/^CO\s+//;
	      $lines[0] =~ s/\s+$//;
	      $self->{_EMBLconstruct} .= $lines[0];
	      shift @lines;
	    }
	    $self->seqHead(">emb|$ac|$ac.$sv ["
			   . $ {$self->{_EMBLscn}}[0] . "]$self->{_EMBLdesc}");
	    next;
	};
	m#^//# && last;
	warn "Unknown line: $_\n";
	shift @lines;
    }
}
#Unknown line: AH   LOCAL_SPAN      PRIMARY_IDENTIFIER   PRIMARY_SPAN     COMP
#Unknown line: AS   1-77            AE008692.2           1911818-1911894  c

sub printEMBL {
    my ($self, $out) = @_;
    print $out "ID   ", $ {$self->{_EMBLac}}[0],
      "; SV $self->{_EMBLsvnb}; $self->{_EMBLtopology}",
      "; $self->{_EMBLtype}; $self->{_EMBLclass}; $self->{_EMBLdivision}",
      "; $self->{_EMBLlen} BP.\n";
    print $out "XX\n";
    my $s = join "; ", @{$self->{_EMBLac}};
    while (length $s > $descrLineLen) {
	my $pos = rindex $s, " ", $descrLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "AC   $ss\n";
    }
    print $out "AC   $s;\n";
    print $out "XX\n";
    if (defined $self->{_EMBLproject}) {
	print $out "PR   ", $self->{_EMBLproject}, "\n";
	print $out "XX\n";
    }
    foreach (@{$self->{_EMBLrev}}) {
	print $out "DT   $_\n";
    }
    print $out "XX\n";
    $s = $self->{_EMBLdesc};
    while (length $s > $descrLineLen) {
	my $pos = rindex $s, " ", $descrLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "DE   $ss\n";
    }
    print $out "DE   $s\n";
    print $out "XX\n";
    foreach (@{$self->{_EMBLkw}}) {
	print $out "KW   $_\n";
    }
    print $out "XX\n";
    my $count;
    my $l = $#{$self->{_EMBLscn}};
    for ($count = 0; $count <= $l; $count++) {
	my $scn = ${$self->{_EMBLscn}}[$count];
	my $comn = ${$self->{_EMBLcomn}}[$count];
	if (defined $comn) {
	    print $out "OS   $scn ($comn)\n";
	} else {
	    print $out "OS   $scn\n";
	}
    }
    $s = $self->{_EMBLtaxo};
    while (length $s > $descrLineLen
	   && !(substr($s, $descrLineLen) =~ /^[.;]$/)) {
	my $pos = rindex $s, " ", $descrLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "OC   $ss\n";
    }
    print $out "OC   $s\n";
    print $out "XX\n";
    if (defined $self->{_EMBLog}) {
	print $out "OG   $self->{_EMBLog}\n";
	print $out "XX\n";
    }
    foreach my $ref (@{$self->{_EMBLlref}}) {
	$ref->print($out, $descrLineLen);
	print $out "XX\n";
    }
    if ($#{$self->{_EMBLdbref}} >= 0) {
	foreach my $ref (@{$self->{_EMBLdbref}}) {
	    $ref->print($out);
	}
	print $out "XX\n";
    }
    if ($#{$self->{_EMBLcc}} >= 0) {
	foreach (@{$self->{_EMBLcc}}) {
	    print $out "CC   $_\n";
	}
	print $out "XX\n";
    }
    if ($#{$self->{_EMBLas}} >= 0) {
	print $out "AH   LOCAL_SPAN      PRIMARY_IDENTIFIER   PRIMARY_SPAN   COMP\n";
	foreach (@{$self->{_EMBLas}}) {
	    print $out "AS   $_\n";
	}
	print $out "XX\n";
    }
    print $out "FH   Key             Location/Qualifiers\n";
    print $out "FH\n";
    foreach (@{$self->{_EMBLft}}) {
	print $out "FT   $_\n";
    }
    print $out "XX\n";
    if ($self->{_EMBLconstruct} ne "") {
      $s = $self->{_EMBLconstruct};
      while (length $s > $descrLineLen
	     && !(substr($s, $descrLineLen) =~ /^[)]$/)) {
	  my $pos = rindex $s, ",", $descrLineLen;
	  my $ss = substr $s, 0, $pos + 1;
	  $s = substr $s, $pos + 1;
	  print $out "CO   $ss\n";
      }
      print $out "CO   $s\n";
    } else {
      print $out "SQ   Sequence $self->{_EMBLlen} BP; $self->{_EMBLcnta} A; "
	  . "$self->{_EMBLcntc} C; $self->{_EMBLcntg} G; $self->{_EMBLcntt} T; "
	      . "$self->{_EMBLcnto} other;\n";
      $count = 0;
      $l = length $self->{_seq};
      while ($l - $count > 60) {
	  $s = substr $self->{_seq}, $count, 60;
	  $s =~ tr/A-Z/a-z/;
	  $s =~ s/(.{10})/$1 /g;
	  $count += 60;
	  print $out "     $s" . " "x(9 - length $count) . "$count\n";
      }
      $s = substr $self->{_seq}, $count, 60;
      $s =~ tr/A-Z/a-z/;
      $s =~ s/(.{10})/$1 /g;
      print $out "     $s" . " "x(75 - (length $s) - (length $l)) . "$l\n";
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
    for ($i = 0; $i <= $#{$self->{_EMBLscn}}; $i++) {
	my $s = $ {$self->{_EMBLscn}}[$i];
	my $c = $ {$self->{_EMBLcomn}}[$i];
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

sub findParts {
    my ($self) = @_;
    # Get expected number of pieces
    my $expected;
    my $de = $self->{_EMBLdesc};
    if ($de =~ /\s+(\d+)\s+(un)?ordered\s+piece/i) {
	$expected = $1;
    } elsif ($de =~ /in ordered piece/i) {
	$expected = 1;
    } elsif ($de =~ /(chromosome|clone).*complete sequence/i) {
	$expected = 1;
    } else {
	foreach (@{$self->{_EMBLkw}}) {
	    if (/HTGS_PHASE3/i) {
		$expected = 1;
		last;
	    }
	}
    }
    # Try to split according to the documentation
    my $c;
    my @part;
    my $N_separation;
    for $c (@{$self->{_EMBLcc}}) {
	if ($c =~ /^\*?\s*(\d+)[-\s]+(\d+):?\s*contig of\s*(\d+)/) {
	    my $start = $1 - 1;
	    my $end = $2;
	    my $len = $3;
	    if ($len != $end - $start) {
		warn "part length problem ($len != $end - $start)"
		  . " in entry " . $ {$self->{_EMBLac}}[0];
	    }
	    push @part, [$start, $len];
	}
	if ($c =~ /^contig\s*\d+\s+(\d+)\.\.(\d+)/) {
	    my $start = $1 - 1;
	    my $len = $2 - $start;
	    push @part, [$start, $len];
	}
	if ($c =~ /(\d+)\s*[Nn].*separate/) {
	    $N_separation = $1 unless defined $N_separation;
	}
    }
    if (defined($expected) && $expected > $#part + 1) {
	undef @part;
	my $cc = "";
	for my $c (@{$self->{_EMBLcc}}) {
	    $cc .= " " . $c;
	}
	my @l = split / gap /, $cc;
	for my $c (@l) {
	    if ($c =~ /(\d+)[-\s]+(\d+):?\s*contig of\s*(\d+)\s*bp/) {
		my $start = $1 - 1;
		my $end = $2;
		my $len = $3;
		if ($len != $end - $start) {
		  warn "part length problem ($len != $end - $start)"
		    . " in entry " . $ {$self->{_EMBLac}}[0];
		}
		push @part, [$start, $len];
	    }
	}
    }
    if ($#part < 0 && $N_separation > 0) {
	# Split the sequence according to Ns markers
	my $Ns = "N"x$N_separation;
	my $last = 0;
	my $end;
	while (($end = index($self->{_seq}, $Ns, $last)) >= 0) {
	    push @part, [$last, $end - $last];
	    $last = $end + $N_separation;
	}
	push @part, [$last, $self->{_EMBLlen} - $last];
    }
    if ($#part < 0) {
	push @part, [0, $self->{_EMBLlen}];
	if (! defined($expected)) {
	    $expected = 1;
	}
    } elsif (! defined($expected) || $expected <= $#part) {
	# If we found some parts description, but don't know
	# how many to expect, or we expected less, we assume it is OK...
	$expected = $#part + 1;
    }
    return ($expected, \@part);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
