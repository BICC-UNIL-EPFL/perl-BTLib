package UGdbref;
use strict;
use vars qw($VERSION);

$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    $self->{_DBRname} = undef;
    $self->{_DBRorg} = undef;
    $self->{_DBRac} = undef;
    $self->{_DBRgi} = undef;
    $self->{_DBRpct} = undef;
    $self->{_DBRaln} = undef;
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

sub parse {
    my ($self, $strr) = @_;
    my ($name, $ac);
    if ($$strr =~ /^PROTSIM/) {
	$$strr =~ s/^(\S+)\s+ORG=([^;]+);\s+PROTGI=([^;]+);\s+PROTID=([^;]+);\s+PCT=([^;]+);\s+ALN=(\d+)//;
	$name = $1;
	$ac = $4;
	$self->{_DBRgi} = $3;
	$self->{_DBRorg} = $2;
	$self->{_DBRpct} = $5;
	$self->{_DBRaln} = $6;
    } else {
	$$strr =~ s/^(\S+)\s+ACC=([^;\s]*)//;
	$name = $1;
	$ac = $2;
    }
    if ($name eq "") {
	warn "Could not parse database reference:\n  $$strr\n";
	return;
    }
    $$strr =~ s/^[;\s]+//;
    $self->{_DBRname} = $name;
    $self->{_DBRac} = $ac;
    $self->{_DBRnote} = $$strr;
}

sub print {
    my ($self, $out) = @_;
  SWITCH:
    for ($self->{_DBRname}) {
	/^PROTSIM$/ && do {
	    print $out "PROTSIM     ORG=$self->{_DBRorg}; PROTGI=$self->{_DBRgi}; PROTID=$self->{_DBRac}; PCT=$self->{_DBRpct}; ALN=$self->{_DBRaln}\n";
	    last SWITCH;
	};
	/^STS$/ && do {
	    print $out "STS         ACC=$self->{_DBRac} $self->{_DBRnote}\n";
	    last SWITCH;
	};
	print $out $self->{_DBRname};
	print $out " "x(12 - length $self->{_DBRname});
	print $out "ACC=$self->{_DBRac}; $self->{_DBRnote}\n";
	last SWITCH;
    }
}

package UGseqref;
use strict;
use vars qw($VERSION);
use EMBLEntry;

$VERSION = "0.23";

# Preloaded methods go here.

# Needs the cluster number.
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = {};
    $self->{_SRclusterNb} = shift;
    $self->{_SRac} = undef;
    $self->{_SRni} = undef;
    $self->{_SRpid} = undef;
    $self->{_SRclone} = undef;
    $self->{_SRend} = undef;
    $self->{_SRlid} = undef;
    $self->{_SRmgc} = undef;
    $self->{_SRtype} = undef;
    $self->{_SRtrace} = undef;
    $self->{_SRnote} = undef;
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
#    warn "Destroying $self";
}

sub parse {
    my ($self, $strr) = @_;
    my ($ni, $pid, $clone, $end, $lid, $mgc, $type,
	$trace, $note, $peripheral);
    $$strr =~ s/^SEQUENCE +ACC=([^.;]+)//;
    my $ac = $1;
    if ($ac eq "") {
	warn "Could not parse sequence reference:\n  $$strr\n";
	return;
    }
    $$strr =~ s/^[.\d;\s]+//;
    while (length($$strr) > 0) {
	if ($$strr =~ /^NID/) {
	    $$strr =~ s/^NID=([^;]+)//;
	    $ni = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^PID/) {
	    $$strr =~ s/^PID=([^;]+)//;
	    $pid = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^CLONE/) {
	    $$strr =~ s/^CLONE=(\S+)//;
	    $clone = $1;
	    $clone =~ s/;$//;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^END/) {
	    $$strr =~ s/^END=([^;]+)//;
	    $end = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^LID/) {
	    $$strr =~ s/^LID=([^;]+)//;
	    $lid = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^MGC/) {
	    $$strr =~ s/^MGC=([^;]+)//;
	    $mgc = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^SEQTYPE/) {
	    $$strr =~ s/^SEQTYPE=([^;]+)//;
	    $type = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^TRACE/) {
	    $$strr =~ s/^TRACE=([^;]+)//;
	    $trace = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	if ($$strr =~ /^PERIPHERAL/) {
	    $$strr =~ s/^PERIPHERAL=([^;]+)//;
	    $peripheral = $1;
	    $$strr =~ s/^[;\s]+//;
	    next;
	}
	$$strr =~ s/^([^;]+)//;
	if (defined $note) {
	    $note .= "; $1";
	} else {
	    $note = $1;
	}
	$$strr =~ s/^[;\s]+//;
    }
    $self->{_SRac} = $ac;
    $self->{_SRni} = $ni;
    $self->{_SRpid} = $pid;
    $self->{_SRclone} = $clone;
    $self->{_SRend} = $end;
    $self->{_SRlid} = $lid;
    $self->{_SRmgc} = $mgc;
    $self->{_SRtype} = $type;
    $self->{_SRtrace} = $trace;
    $self->{_SRperipheral} = $peripheral;
    if ($note ne "") {
	warn "Found sequence note: $note";
	$self->{_SRnote} = $note;
    }
}

sub print {
    my ($self, $out) = @_;
    print $out "SEQUENCE    ACC=$self->{_SRac}";
    if (defined $self->{_SRni}) {
	print $out "; NID=$self->{_SRni}";
    }
    if (defined $self->{_SRpid}) {
	print $out "; PID=$self->{_SRpid}";
    }
    if (defined $self->{_SRclone}) {
	print $out "; CLONE=$self->{_SRclone}";
    }
    if (defined $self->{_SRend}) {
	print $out "; END=$self->{_SRend}";
    }
    if (defined $self->{_SRlid}) {
	print $out "; LID=$self->{_SRlid}";
    }
    if (defined $self->{_SRmgc}) {
	print $out "; MGC=$self->{_SRmgc}";
    }
    if (defined $self->{_SRtype}) {
	print $out "; SEQTYPE=$self->{_SRtype}";
    }
    if (defined $self->{_SRtrace}) {
	print $out "; TRACE=$self->{_SRtrace}";
    }
    if (defined $self->{_SRnote}) {
	print $out "; $self->{_SRnote}";
    }
    print $out "\n";
}

sub fetch {
    my ($self, $ef) = @_;
    my $e = $ef->fetch("$self->{_SRac}.$self->{_SRclusterNb}");
    if (!defined($e) && defined($main::embl_f)) {
	my $ee = $main::embl_f->fetch($self->{_SRac});
	if (defined($ee) && ($ee->EMBLtype eq "RNA")) {
	    $e = FASTAEntry->new;
	    $e->{_seq} = $ee->{_seq};
	    $e->{_seqHead} = $ee->{_seqHead};
	    $e->{_FASTAdb} = "emb";
	    $e->{_FASTAac} = $ee->ac;
	    $e->{_FASTAid} = $ee->id;
	    $e->{_FASTAos} = $ee->{_EMBLscn};
	    $e->{_FASTAde} = $ee->de;
	}
    }
    warn "Could not find ACC $self->{_SRac} for cluster $self->{_SRclusterNb}"
	unless defined $e;
    return $e;
}

package UGEntry;

# We define an object that attempts to represent an UG entry.

use strict;
use vars qw($VERSION);

$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    $self->{_UGname} = undef;
    $self->{_UGtitle} = undef;
    $self->{_UGknown} = undef;
    $self->{_UGgene} = undef;
    $self->{_UGchrom} = undef;
    $self->{_UGband} = undef;
    $self->{_UGlocuslink} = undef;
    $self->{_UGhomol} = undef; 
    $self->{_UGpolya} = undef;
    $self->{_UGexpress} = undef;
    $self->{_UGrestrexpr} = undef;
    $self->{_UGtxmap} = undef;
    $self->{_UGmgi} = undef;
    $self->{_UGscount} = undef;
    $self->{_UGgt} = undef;
    $self->{_UGdbref} = [];
    $self->{_UGsref} = [];
    $self->{_UGseq} = [];
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
}

sub name {
    my $self = shift;
    if (@_) {
	$self->{_UGname} = shift;
    }
    return $self->{_UGname};
}

sub title {
    my $self = shift;
    if (@_) {
	$self->{_UGtitle} = shift;
    }
    return $self->{_UGtitle};
}

sub gene {
    my $self = shift;
    if (@_) {
	$self->{_UGgene} = shift;
    }
    return $self->{_UGgene};
}

sub known {
    my $self = shift;
    if (@_) {
	$self->{_UGknown} = shift;
    }
    return $self->{_UGknown};
}

sub scount {
    my $self = shift;
    if (@_) {
	$self->{_UGscount} = shift;
    }
    return $self->{_UGscount};
}

sub getSeq {
    my ($self, $nb) = @_;
    if ($nb < 0 || $nb > $#{$self->{_UGseq}}) {
	return undef;
    }
    return $ {$self->{_UGseq}}[$nb];
}

sub firstProtSim {
    my $self = shift;
    if ($#{$self->{_UGdbref}} >= 0) {
	foreach my $ref (@{$self->{_UGdbref}}) {
	    if ($ref->name =~ /protsim/i) {
		return $ref->ac;
	    }
	}
    }
    return undef;
}

sub parse {
    my ($self, $strr) = @_;
    my @lines = split /\n/, $$strr;
    # Get the ID line.
    my $s = shift @lines;
    my ($n) = $s =~ /^ID\s+(\S+)/;
    if ($n eq "") {
	warn "Could not parse UG entry:\n$$strr";
	return;
    }
    my $cNb = $n;
    $cNb =~ s/^[A-Za-z.]+//; # The cluster number
    $self->{_UGname} = $n;
    while (defined ($_ = $lines[0])) {
	/^TITLE/ && do {
	    s/^TITLE\s+//;
	    s/\s$//;
	    if (/^EST/) {
		$self->{_UGknown} = 0;
	    } else {
		$self->{_UGknown} = 1;
	    }
	    $self->{_UGtitle} = $_;
	    shift @lines;
	    next;
	};
	/^GENE/ && do {
	    s/^GENE\s+//;
	    s/\s$//;
	    $self->{_UGgene} = $_;
	    shift @lines;
	    next;
	};
	/^CHROMOSOME/ && do {
	    s/^CHROMOSOME\s+//;
	    s/\s$//;
	    $self->{_UGchrom} = $_;
	    shift @lines;
	    next;
	};
	/^CYTOBAND/ && do {
	    s/^CYTOBAND\s+//;
	    s/\s$//;
	    $self->{_UGband} = $_;
	    shift @lines;
	    next;
	};
	/^MGI/ && do {
	    s/^MGI\s+//;
	    s/\s$//;
	    $self->{_UGmgi} = $_;
	    shift @lines;
	    next;
	};
	/^LOCUSLINK/ && do {
	    s/^LOCUSLINK\s+//;
	    s/\s$//;
	    $self->{_UGlocuslink} = $_;
	    shift @lines;
	    next;
	};
	/^HOMOL/ && do {
	    s/^HOMOL\s+//;
	    s/\s$//;
	    $self->{_UGhomol} = $_;
	    shift @lines;
	    next;
	};
	/^POLY_A/ && do {
	    s/^POLY_A\s+//;
	    s/\s$//;
	    $self->{_UGpolya} = $_;
	    shift @lines;
	    next;
	};
	/^GENOME_TERMINUS/ && do {
	    s/^GENOME_TERMINUS\s+//;
	    s/\s$//;
	    $self->{_UGgt} = $_;
	    shift @lines;
	    next;
	};
	/^GNM_TERMINUS/ && do {
	    s/^GNM_TERMINUS\s+//;
	    s/\s$//;
	    $self->{_UGgt} = $_;
	    shift @lines;
	    next;
	};
	/^EXPRESS/ && do {
	    s/^EXPRESS\s+//;
	    s/\s$//;
	    $self->{_UGexpress} = $_;
	    shift @lines;
	    next;
	};
	/^RESTR_EXPR/ && do {
	    s/^RESTR_EXPR\s+//;
	    s/\s$//;
	    $self->{_UGrestrexpr} = $_;
	    shift @lines;
	    next;
	};
	/^TXMAP/ && do {
	    s/^TXMAP\s+//;
	    s/\s$//;
	    $self->{_UGtxmap} = $_;
	    shift @lines;
	    next;
	};
	/^SCOUNT/ && do {
	    s/^SCOUNT\s+//;
	    s/\s$//;
	    $self->{_UGscount} = $_;
	    shift @lines;
	    next;
	};
	/^SEQUENCE/ && do {
	    s/\s$//;
	    my $ref = UGseqref->new($cNb);
	    $ref->parse(\$lines[0]);
	    push @{$self->{_UGsref}}, $ref;
	    shift @lines;
	    next;
	};
	/^STS|PROTSIM/ && do {
	    s/\s$//;
	    my $ref = UGdbref->new;
	    $ref->parse(\$lines[0]);
	    push @{$self->{_UGdbref}}, $ref;
	    shift @lines;
	    next;
	};
	m#^//# && last;
	warn "Unknown line: $_\n";
	shift @lines;
    }
    my $nbs = $#{$self->{_UGsref}} + 1;
    if ($nbs != $self->{_UGscount}) {
	warn "Wrong number of sequences in $self->{_UGname}\n"
	    . "Expected $self->{_UGscount}, actual: $nbs";
	$self->{_UGscount} = $nbs;
    }
}

sub printUG {
    my ($self, $out) = @_;
    print $out "ID          $self->{_UGname}\n";
    print $out "TITLE       $self->{_UGtitle}\n";
    if (defined $self->{_UGgene}) {
	print $out "GENE        $self->{_UGgene}\n";
    }
    if (defined $self->{_UGband}) {
	print $out "CYTOBAND    $self->{_UGband}\n";
    }
    if (defined $self->{_UGmgi}) {
	print $out "MGI         $self->{_UGmgi}\n";
    }
    if (defined $self->{_UGlocuslink}) {
	print $out "LOCUSLINK   $self->{_UGlocuslink}\n";
    }
    if (defined $self->{_UGexpress}) {
	print $out "EXPRESS     $self->{_UGexpress}\n";
    }
    if (defined $self->{_UGgt}) {
	print $out "GNM_TERMINUS      $self->{_UGgt}\n";
    }
    if (defined $self->{_UGchrom}) {
	print $out "CHROMOSOME  $self->{_UGchrom}\n";
    }
    if (defined $self->{_UGtxmap}) {
	print $out "TXMAP       $self->{_UGtxmap}\n";
    }
    if ($#{$self->{_UGdbref}} >= 0) {
	foreach my $ref (@{$self->{_UGdbref}}) {
	    $ref->print($out);
	}
    }
    print $out "SCOUNT      $self->{_UGscount}\n";
    if ($#{$self->{_UGsref}} >= 0) {
	foreach my $ref (@{$self->{_UGsref}}) {
	    $ref->print($out);
	}
    }
    print $out "//\n";
}

sub getAllSeq {
    my ($self, $ef) = @_;
    my $realcounts = 0;
    foreach my $ref (@{$self->{_UGsref}}) {
	my $seq = $ref->fetch($ef);
	if (defined $seq) {
	    push @{$self->{_UGseq}}, $seq;
	    $realcounts++;
	}
    }
    return $realcounts;
}

sub storeSeqFASTA {
    my ($self, $ff, $start, $end) = @_;
    if (!defined($start) || $start < 0) {
	$start = 0;
    }
    if (!defined($end) || $end > $#{$self->{_UGseq}}) {
	$end = $#{$self->{_UGseq}};
    }
    for (my $i = $start; $i <= $end; $i++) {
	my $seq = $ {$self->{_UGseq}}[$i];
	if (defined $seq) {
	    $ff->appendSeq($seq);
	}
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
