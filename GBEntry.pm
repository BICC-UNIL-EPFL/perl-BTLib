package GBEntry;

# We define an object that attempts to represent a GenBank entry.

use strict;
use vars qw($VERSION @ISA);

@ISA = qw(BTLib);
$VERSION = "0.23";

# Tweaking factor.
my $descrLineLen = 70;

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new();
    $self->{_GBname} = undef;
    $self->{_GBtype} = undef;
    $self->{_GBac} = [];
    $self->{_GBdesc} = undef;
    $self->{_GBscn} = undef;
    $self->{_GBcomn} = undef;
    $self->{_GBsv} = undef;
    $self->{_GBgi} = undef;
    $self->{_GBcdssst} = undef;
    $self->{_GBcdssen} = undef;
    $self->{_GBconstruct} = undef;
    $self->{_GBpiece} = undef;
    $self->{_GBlen} = undef;
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
	$self->{_GBdesc} = shift;
    }
    return $self->{_GBdesc};
}

sub firstAC {
    my $self = shift;
    return $ {$self->{_GBac}}[0];
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{_GBname} = shift;
    }
    return $self->{_GBname};
}

sub parse {
    my ($self, $strr) = @_;
    my @lines = split /\n/, $$strr;
    # This is realy minimalistic...
    $_ = shift @lines;
    my ($n) = $_ =~
	/^LOCUS\s+(\w+)/;
    if ($n eq "") {
	warn "Could not parse GB entry:\n$$strr";
	return;
    }
    $self->{_GBname} = $n;
    $self->{_GBtype} = substr $_, 47, 7;
    $self->{_GBtype} =~ s/\s+$//;
    while (defined ($_ = $lines[0])) {
	/^DEFINITION/ && do {
	    s/^DEFINITION\s+//;
	    my $de = $_;
	    while ($lines[1] =~ /^\s/) {
		$de .= $lines[1];
		shift @lines;
	    }
	    $de =~ s/\s+/ /g;
	    $de =~ s/[\s.]+$//;
	    $self->{_GBdesc} = $de;
	    shift @lines;
	    next;
	};
	/^ACCESSION/ && do {
	    s/^ACCESSION\s+//;
	    push @{$self->{_GBac}}, split;
	    shift @lines;
	    next;
	};
	/^VERSION\s+(\S+)\s+(\S+)/ && do {
	    $self->{_GBsv} = $1;
	    $self->{_GBgi} = lc $2;
	    shift @lines;
	    next;
	};
	s/^SOURCE\s+// && do {
	    s/\.$//;
	    $self->{_GBcomn} = $_;
	    shift @lines;
	    $_ = $lines[0];
	    next unless s/^\s+ORGANISM\s+//;
	    $self->{_GBscn} = $_;
	    my $str = "";
	    while ($lines[1] =~ s/^\s+/ /) {
		$str .= $lines[1];
		shift @lines;
	    }
	    $str =~ s/^\s+//;
	    $self->{_GBtaxo} = $str;
	    shift @lines;
	    next;
	};
	/^FEATURES/ && do {
	    while ($lines[1] =~ /^ /) {
		shift @lines;
		if ($lines[0] =~ /^\s+CDS\s+(\d+)\.\.(\d+)/) {
		    $self->{_GBcdsst} = $1;
		    $self->{_GBcdsen} = $2;
		}
	    }
	    shift @lines;
	    next;
	};
	/^ORIGIN/ && do {
	    shift @lines;
	    $self->{_seq} .= '';
	    while($_ = shift @lines) {
		s/[\s0-9\/]//g;
		tr/a-z/A-Z/;
		$self->{_seq} .= $_;
	    }
	    my $ac = $ {$self->{_GBac}}[0];
	    my $os = $self->{_GBscn};
	    $self->seqHead(">rs|$ac|$self->{_GBsv} [$os]$self->{_GBdesc}");
	    next;
	};
	s/^CONTIG\s+// && do {
	    while ($lines[1] =~ s/^\s+//) {
		$_ .= $lines[1];
		shift @lines;
	    }
	    shift @lines;
	    $self->{_GBconstruct} = $_;
	    my $ac = $ {$self->{_GBac}}[0];
	    my $os = $self->{_GBscn};
	    my $de = $self->{_GBdesc};
	    if ($de =~ s/^$os chromosome ([^, ]+)[, ]+//) {
	      $self->seqHead(">chr|$ac|$self->{_GBsv} Chromosome $1; [$os]"
			     . " $self->{_GBgi} $de");
	    } else {
	      $self->seqHead(">rs|$ac|$self->{_GBsv} [$os]$de");
	    }
	    next;
	};
	m"^//" && last;
	shift @lines;
    }
}

sub printGB {
    my ($self, $out) = @_;
    print $out "LOCUS       $self->{_GBname}\n";
    print $out "DEFINITION  $self->{_GBdesc}.\n";
    print $out "ACCESSION   ", join(" ", @{$self->{_GBac}}), "\n";
    print $out "VERSION     $self->{_GBsv}  $self->{_GBgi}\n";
    print $out "KEYWORDS    .\n";
    print $out "SOURCE      $self->{_GBcomn}.\n";
    print $out "  ORGANISM  $self->{_GBscn}\n";
    my $s = $self->{_GBtaxo};
    while (length $s > $descrLineLen
	   && !(substr($s, $descrLineLen) =~ /^[.;]$/)) {
	my $pos = rindex $s, " ", $descrLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "            $ss\n";
    }
    print $out "            $s\n";
    print $out "//\n";
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
