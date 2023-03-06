package EPDdbref;
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
    $self->{_DBRsv} = undef;
    $self->{_DBRstart} = undef;
    $self->{_DBRend} = undef;
    $self->{_DBRattr} = undef;
    $self->{_DBRnote} = undef;
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
#    warn "Destroying $self";
}

sub name {
    my $self = shift;
    if (@_) {
	$self->{_DBRname} = shift;
    }
    return $self->{_DBRname};
}

sub ac {
    my $self = shift;
    if (@_) {
	$self->{_DBRac} = shift;
    }
    return $self->{_DBRac};
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{_DBRid} = shift;
    }
    return $self->{_DBRid};
}

sub sv {
    my $self = shift;
    if (@_) {
	$self->{_DBRsv} = shift;
    }
    return $self->{_DBRsv};
}

sub start {
    my $self = shift;
    if (@_) {
	$self->{_DBRstart} = shift;
    }
    return $self->{_DBRstart};
}

sub end {
    my $self = shift;
    if (@_) {
	$self->{_DBRend} = shift;
    }
    return $self->{_DBRend};
}

sub attr {
    my $self = shift;
    if (@_) {
	$self->{_DBRattr} = shift;
    }
    return $self->{_DBRattr};
}

sub note {
    my $self = shift;
    if (@_) {
	$self->{_DBRnote} = shift;
    }
    return $self->{_DBRnote};
}

sub parse {
    my ($self, $strr) = @_;
    my ($ac, $id, $sv, $start, $end, $attr, $note);
    my ($name) = $$strr =~ /^DR   ([-\w]+); /;
    $$strr =~ s/^DR   [-\w]+; //;
    if ($name eq "") {
	warn "Could not parse database reference:\n  $$strr\n";
	return;
    }
  SWITCH:
    for ($name) {
	/^EMBL$/ && do {
	    ($sv, $id, $start, $end, $note)
		= $$strr =~ /^(\S+); (\w+); \[([-+\d]+),\s*([-+\d]+)\]\.(.*)/;
	    if ($sv eq "") {
		warn "Badly formatted EMBL reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^SWISS-PROT$/ && do {
	    ($ac, $id, $note)
		= $$strr =~ /^(\w+); (\w+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted SWISS-PROT reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^EPD$/ && do {
	    ($ac, $id, $attr, $note)
		= $$strr =~ /^(\w+); (\w+); (.+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted EPD reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^TRANSFAC$/ && do {
	    ($ac, $id, $start, $end, $attr, $note)
		= $$strr =~ /^(\w+); ([-\w\$]+); \[([-+\d]+),\s*([-+\d]+)\][,;] ([^.]+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted TRANSFAC reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^FLYBASE$/ && do {
	    ($ac, $id, $note)
		= $$strr =~ /^([\[\]\w]+); ([-\\\[\]:()&\w]+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted FLYBASE reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^MIM$/ && do {
	    ($ac, $note)
		= $$strr =~ /^(\d+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted MIM reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^EPDEX|RefSeq$/ && do {
	    ($ac, $note)
		= $$strr =~ /^(\w+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted EPDEX reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	/^MGD$/ && do {
	    ($ac, $id, $note)
		= $$strr =~ /^([^;]+); ([^.]+)\.(.*)/;
	    if ($ac eq "") {
		warn "Badly formatted MGD reference:\n  $$strr\n";
	    }
	    last SWITCH;
	};
	warn "Unknown database reference: $name $$strr\n";
    }
    $self->{_DBRname} = $name;
    $self->{_DBRac} = $ac;
    $self->{_DBRid} = $id;
    $self->{_DBRsv} = $sv;
    $self->{_DBRstart} = $start;
    $self->{_DBRend} = $end;
    $self->{_DBRattr} = $attr;
    $self->{_DBRnote} = $note;
}

sub print {
    my ($self, $out) = @_;
  SWITCH:
    for ($self->{_DBRname}) {
	/^EMBL$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRsv}; $self->{_DBRid}; "
		. "[$self->{_DBRstart},$self->{_DBRend}]."
		    . "$self->{_DBRnote}\n";
	    last SWITCH;
	};
	/^(SWISS-PROT|FLYBASE|MGD)$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}; "
		. "$self->{_DBRid}.$self->{_DBRnote}\n";
	    last SWITCH;
	};
	/^EPD$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}; $self->{_DBRid}; "
		. "$self->{_DBRattr}.$self->{_DBRnote}\n";
	    last SWITCH;
	};
	/^TRANSFAC$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}; $self->{_DBRid}; "
		. "[$self->{_DBRstart},$self->{_DBRend}]; $self->{_DBRattr}."
		    . "$self->{_DBRnote}\n";
	    last SWITCH;
	};
	/^MIM$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}."
		. "$self->{_DBRnote}\n";
	    last SWITCH;
	};
	/^EPDEX|RefSeq$/ && do {
	    print $out "DR   $self->{_DBRname}; $self->{_DBRac}."
		. "$self->{_DBRnote}\n";
	    last SWITCH;
	};
	warn "Unknown database format $self->{_DBRname}\n";
    }
}

package EPDEntry;

# We define an object that attempts to represent an EPD entry.
#
# _EPDname: scalar, ID name.
# _EPDattr: array, attributes.
# _EPDclass: scalar, classification.
# _EPDac: scalar, accession number.
# _EPDrev: array, revision information.
# _EPDdesc: scalar, description.
# _EPDdbref: array of dbref, references to other databases.
# _EPDlref: array of lref, references to the litterature.
# _EPDmethod: array of methods, methods.
# _EPDtax: array, taxonomy.
# _EPDfp: scalar, magic ???
# _EPDdo: array, experimental data ?
# _EPDrf: scalar, references ?

use strict;
use vars qw($VERSION @ISA);
use BTLib;
use LitRef;

@ISA = qw(BTLib);
$VERSION = "0.23";

# Tweaking factor.
my $descrLineLen = 66;

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new();
    $self->{_EPDname} = undef;
    $self->{_EPDattr} = undef;
    $self->{_EPDclass} = undef;
    $self->{_EPDac} = undef;
    $self->{_EPDrev} = [];
    $self->{_EPDdesc} = undef;
    $self->{_EPDkw} = undef;
    $self->{_EPDscn} = undef;
    $self->{_EPDcomn} = undef;
    $self->{_EPDhg} = [];
    $self->{_EPDaltp} = undef;
    $self->{_EPDnp} = [];
    $self->{_EPDdbref} = [];
    $self->{_EPDlref} = undef;
    $self->{_EPDmethod} = [];
    $self->{_EPDfl} = undef;
    $self->{_EPDif} = [];
    $self->{_EPDtaxo} = [];
    $self->{_EPDfp} = undef;
    $self->{_EPDdo} = undef;
    $self->{_EPDrf} = undef;
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
	$self->{_EPDdesc} = shift;
    }
    return $self->{_EPDdesc};
}

sub scn {
    my $self = shift;
    if (@_) {
	$self->{_EPDscn} = shift;
    }
    return $self->{_EPDscn};
}

sub comn {
    my $self = shift;
    if (@_) {
	$self->{_EPDcomn} = shift;
    }
    return $self->{_EPDcomn};
}

sub pushDT {
    my ($self, $dt) = @_;
    push @{$self->{_EPDrev}}, $dt;
};

sub parse {
    my ($self, $strr) = @_;
    my @lines = split /\n/, $$strr;
    # Get the ID line.
    my $s = shift @lines;
    my ($n, $attr, $c) = $s =~ /^ID   (\w+)\s+([\w; ]+); (\w+)\./;
    if ($n eq "") {
	warn "Could not parse EPD entry:\n$$strr";
	return;
    }
    $self->{_EPDname} = $n;
    $self->{_EPDclass} = $c;
    $attr =~ s/ //g;
    my @attrs = split /;/, $attr;
    $self->{_EPDattr} = [ @attrs ];
    while (defined ($_ = $lines[0])) {
	/^XX/ && do {
	    shift @lines;
	    next;
	};
	/^AC/ && do {
	    ($self->{_EPDac}) = /^AC   (\w+);/;
	    if ($self->{_EPDac} eq "") {
		warn "Bad AC line in:\n$$strr";
	    }
	    shift @lines;
	    next;
	};
	/^DT/ && do {
	    s/^DT   //;
	    s/\s+$//;
	    push @{$self->{_EPDrev}}, $_;
	    shift @lines;
	    next;
	};
	/^DE/ && do {
	    s/^DE//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_EPDdesc}) {
		$self->{_EPDdesc} .= " $_";
	    } else {
		$self->{_EPDdesc} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^KW/ && do {
	    s/^KW//;
	    s/^\s+//;
	    s/\s+$//;
	    if (defined $self->{_EPDkw}) {
		$self->{_EPDkw} .= " $_";
	    } else {
		$self->{_EPDkw} = $_;
	    }
	    shift @lines;
	    next;
	};
	/^OS/ && do {
	    my ($sn, $com);
	    if (index($_, "(") >= 0) {
		($sn, $com) = /^OS   ([^(]+)\((.+)\)/;
	    } else {
		s/^OS//;
		s/^\s+//;
		$sn = $_;
	    }
	    $sn =~ s/\.?\s*$//;
	    $self->{_EPDscn} = $sn;
	    $self->{_EPDcomn} = $com;
	    shift @lines;
	    next;
	};
	/^HG/ && do {
	    s/^HG   //;
	    s/\s+$//;
	    push @{$self->{_EPDhg}}, $_;
	    shift @lines;
	    next;
	};
	/^AP/ && do {
	    s/^AP   //;
	    s/\s+$//;
	    $self->{_EPDaltp} = $_;
	    shift @lines;
	    next;
	};
	/^NP/ && do {
	    s/^NP   //;
	    s/\s+$//;
	    push @{$self->{_EPDnp}}, $_;
	    shift @lines;
	    next;
	};
	/^DR/ && do {
	    my $ref = EPDdbref->new;
	    $ref->parse(\$lines[0]);
	    push @{$self->{_EPDdbref}}, $ref;
	    shift @lines;
	    next;
	};
	/^RN/ && do {
	    my $ref = LitRef->new;
	    $ref->parse(\@lines);
	    push @{$self->{_EPDlref}}, $ref;
	    next;
	};
	/^ME/ && do {
	    s/^ME   //;
	    s/\s+$//;
	    push @{$self->{_EPDmethod}}, $_;
	    shift @lines;
	    next;
	};
	/^SE/ && do {
	    s/^SE   //;
	    s/\s+$//;
	    $self->seq($_);
	    $self->seqHead(">epd|$self->{_EPDac}|$self->{_EPDname}");
	    shift @lines;
	    next;
	};
	/^FL/ && do {
	    s/^FL   //;
	    s/\s+$//;
	    $self->{_EPDfl} = $_;
	    shift @lines;
	    next;
	};
	/^IF/ && do {
	    s/^IF//;
	    s/\s+$//;
	    push @{$self->{_EPDif}}, $_;
	    shift @lines;
	    next;
	};
	/^TX/ && do {
	    s/^TX   //;
	    s/\s+$//;
	    push @{$self->{_EPDtaxo}}, $_;
	    shift @lines;
	    next;
	};
	/^FP/ && do {
	    s/^FP   //;
	    s/\s+$//;
	    $self->{_EPDfp} = $_;
	    shift @lines;
	    next;
	};
	/^DO/ && do {
	    s/^DO   //;
	    s/\s+$//;
	    push @{$self->{_EPDdo}}, $_;
	    shift @lines;
	    next;
	};
	/^RF/ && do {
	    s/^RF   //;
	    s/\s+$//;
	    $self->{_EPDrf} = $_;
	    shift @lines;
	    next;
	};
	m#^//# && last;
	warn "Unknown line: $_\n";
	shift @lines;
    }
}

sub print {
    my ($self, $out) = @_;
    print $out "ID   $self->{_EPDname}     ";
    foreach (@{$self->{_EPDattr}}) {
	print $out "$_; ";
    }
    print $out "$self->{_EPDclass}.\n";
    print $out "XX\n";
    print $out "AC   $self->{_EPDac};\n";
    print $out "XX\n";
    foreach (@{$self->{_EPDrev}}) {
	print $out "DT   $_\n";
    }
    print $out "XX\n";
    my $s = $self->{_EPDdesc};
    while (length $s > $descrLineLen) {
	my $pos = rindex $s, " ", $descrLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "DE   $ss\n";
    }
    print $out "DE   $s\n";
    if (defined $self->{_EPDcomn}) {
	print $out "OS   $self->{_EPDscn} ($self->{_EPDcomn}).\n";
    } else {
	print $out "OS   $self->{_EPDscn}.\n";
    }
    print $out "XX\n";
    foreach (@{$self->{_EPDhg}}) {
	print $out "HG   $_\n";
    }
    print $out "AP   $self->{_EPDaltp}\n";
    foreach (@{$self->{_EPDnp}}) {
	print $out "NP   $_\n";
    }
    print $out "XX\n";
    foreach (@{$self->{_EPDdbref}}) {
	$_->print($out);
    }
    print $out "XX\n";
    foreach (@{$self->{_EPDlref}}) {
	$_->print($out, $descrLineLen);
    }
    print $out "XX\n";
    foreach (@{$self->{_EPDmethod}}) {
	print $out "ME   $_\n";
    }
    print $out "XX\n";
    my $seqU = substr $self->{_seq}, 0, 49;
    $seqU =~ tr /A-Z/a-z/;
    my $seqD = substr $self->{_seq}, 49;
    $seqD =~ tr /a-z/A-Z/;
    print $out "SE   $seqU$seqD\n";
    print $out "XX\n";
    if (defined $self->{_EPDfl}) {
	print $out "FL   $self->{_EPDfl}\n";
	foreach (@{$self->{_EPDif}}) {
	    print $out "IF$_\n";
	}
	print $out "XX\n";
    }
    foreach (@{$self->{_EPDtaxo}}) {
	print $out "TX   $_\n";
    }
    print $out "XX\n";
    $s = $self->{_EPDkw};
    while (length $s > $descrLineLen) {
	my $pos = rindex $s, " ", $descrLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "KW   $ss\n";
    }
    print $out "KW   $s\n";
    print $out "XX\n";
    print $out "FP   $self->{_EPDfp}\n";
    print $out "XX\n";
    foreach (@{$self->{_EPDdo}}) {
	print $out "DO   $_\n";
    }
    print $out "RF   $self->{_EPDrf}\n";
    print $out "//\n";
}

sub getDbRef {
    my ($self, $db, $ac, $id, $sv, $start, $end, $note) = @_;
    my $i;
    for ($i = 0; $i <= $#{$self->{_EPDdbref}}; $i++) {
	my $ref = $ {$self->{_EPDdbref}}[$i];
	if (defined $db) {
	    next if $ref->name ne $db;
	}
	if (defined $ac) {
	    next if $ref->ac ne $ac;
	}
	if (defined $id) {
	    next if $ref->id ne $id;
	}
	if (defined $sv) {
	    next if $ref->sv ne $sv;
	}
	if (defined $start) {
	    next if $ref->start ne $start;
	}
	if (defined $end) {
	    next if $ref->end ne $end;
	}
	if (defined $note) {
	    next if $ref->note ne $note;
	}
	return $ref;
    }
    return undef;
}

sub addDbRef {
    my ($self, $db, $ac, $id, $sv, $start, $end, $note) = @_;
    my $ref = EPDdbref->new;
    $ref->name($db);
    $ref->ac($ac);
    $ref->id($id);
    $ref->sv($sv);
    $ref->start($start);
    $ref->end($end);
    $ref->note($note);
    my $len = $#{$self->{_EPDdbref}};
    my $i;
    for ($i = 0; $i <= $len; $i++) {
	my $elt = $ {$self->{_EPDdbref}}[$i];
	last if $elt->name eq $db;
    }
    for ( ; $i <= $len; $i++) {
	my $elt = $ {$self->{_EPDdbref}}[$i];
	last if $elt->name ne $db;
    }
    if ($i > $len) {
	push @{$self->{_EPDdbref}}, $ref;
    } else {
	splice(@{$self->{_EPDdbref}}, $i, $len - $i + 1,
	       $ref, @{$self->{_EPDdbref}}[$i..$len]);
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
