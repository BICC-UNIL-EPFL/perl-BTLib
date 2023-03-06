package LitRef;
use strict;
use vars qw($VERSION);

$VERSION = "0.23";

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    $self->{_LRnum} = undef;
    $self->{_LRname} = undef;
    $self->{_LRpart} = undef;
    $self->{_LRc} = undef;
    $self->{_LRgroup} = undef;
    $self->{_LRauth} = undef;
    $self->{_LRtitle} = undef;
    $self->{_LRlib} = [];
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
#    warn "Destroying $self";
}

sub parse {
    my ($self, $liner) = @_;
    ($self->{_LRnum}) = $$liner[0] =~ /^RN   \[(\d+)\]/;
    if ($self->{_LRnum} eq "") {
	warn "Bad litterature reference $$liner[0]\n";
	return;
    }
    shift @$liner;
    while (defined ($_ = $$liner[0])) {
	/^RC/ && do {
	    s/^RC   //;
	    s/\s+$//;
	    $self->{_LRc} = $_;
	    shift @$liner;
	    next;
	};
	/^RP/ && do {
	    s/^RP   //;
	    s/\s+$//;
	    $self->{_LRpart} = $_;
	    shift @$liner;
	    next;
	};
	/^RX/ && do {
	    s/^RX   //;
	    s/\s+$//;
	    $self->{_LRname} = $_;
	    shift @$liner;
	    next;
	};
	/^RG/ && do {
	    s/^RG\s*//;
	    s/\s+$//;
	    if (defined $self->{_LRgroup}) {
		$self->{_LRgroup} .= " $_";
	    } else {
		$self->{_LRgroup} = $_;
	    }
	    shift @$liner;
	    next;
	};
	/^RA/ && do {
	    s/^RA\s*//;
	    s/\s+$//;
	    if (defined $self->{_LRauth}) {
		$self->{_LRauth} .= " $_";
	    } else {
		$self->{_LRauth} = $_;
	    }
	    shift @$liner;
	    next;
	};
	/^RT/ && do {
	    s/^RT\s*//;
	    s/\s+$//;
	    if (defined $self->{_LRtitle}) {
		$self->{_LRtitle} .= " $_";
	    } else {
		$self->{_LRtitle} = $_;
	    }
	    shift @$liner;
	    next;
	};
	/^RL/ && do {
	    s/^RL   //;
	    s/\s+$//;
	    push @{$self->{_LRlib}}, $_;
	    shift @$liner;
	    next;
	};
	last;
    }
    $self->{_LRtitle} =~ s/^"//; #"
    $self->{_LRtitle} =~ s/";$//; #"
    if ($self->{_LRtitle} eq ";") {
	$self->{_LRtitle} = undef;
    }
}

sub print {
    my ($self, $out, $refLineLen) = @_;
    print $out "RN   [$self->{_LRnum}]\n";
    if (defined $self->{_LRpart}) {
	print $out "RP   $self->{_LRpart}\n";
    }
    if (defined $self->{_LRc}) {
	print $out "RC   $self->{_LRc}\n";
    }
    if (defined $self->{_LRname}) {
	print $out "RX   $self->{_LRname}\n";
    }
    if (defined $self->{_LRgroup}) {
	my $s = $self->{_LRgroup};
	while (length $s > $refLineLen
	       && !(substr($s, $refLineLen) =~ /^;$/)) {
	    my $pos = rindex $s, ", ", $refLineLen;
	    my $ss = substr $s, 0, $pos+1;
	    $s = substr $s, $pos + 2;
	    print $out "RG   $ss\n";
	}
	print $out "RG   $s\n";
    }
    my $s = $self->{_LRauth};
    while (length $s > $refLineLen
	   && !(substr($s, $refLineLen) =~ /^;$/)) {
	my $pos = rindex $s, ", ", $refLineLen;
	my $ss = substr $s, 0, $pos+1;
	$s = substr $s, $pos + 2;
	print $out "RA   $ss\n";
    }
    print $out "RA   $s\n";
    if (defined $self->{_LRtitle}) {
	$s = "\"$self->{_LRtitle}\";";
    } else {
	$s = ";";
    }
    while (length $s > $refLineLen
	   && !(substr($s, $refLineLen) =~ /^;$/)) {
	my $pos = rindex $s, " ", $refLineLen;
	my $ss = substr $s, 0, $pos;
	$s = substr $s, $pos + 1;
	print $out "RT   $ss\n";
    }
    print $out "RT   $s\n";
    foreach (@{$self->{_LRlib}}) {
	print $out "RL   $_\n";
    }
}
