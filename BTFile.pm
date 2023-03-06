# A generic file object, used by other BTLib packages.
package BTFile;

use strict;
use vars qw($VERSION);
use Symbol;
use locale;
use POSIX qw( O_RDONLY SEEK_SET );
use File::Temp qw/ :POSIX /;
use POSIX qw( locale_h );
use IPC::Open3;

$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my ($proto, $path, $ext, $dPath, $idLen, $posLen, $lenLen) = @_;
    my $class = ref $proto || $proto;
    my $self  = {};
    if (defined $idLen) {
	$self->{_BTFidLen} = $idLen;
    } else {
	$self->{_BTFidLen} = 14;
    }
    if (defined $posLen) {
	$self->{_BTFposLen} = $posLen;
    } else {
	$self->{_BTFposLen} = 10;
    }
    if (defined $lenLen) {
	$self->{_BTFlenLen} = $lenLen;
    } else {
	$self->{_BTFlenLen} = 6;
    }
    if (defined $path) {
	if ($path =~ s/\[(\d*),(\d*),(\d*)\]$//) {
	    if ($1 ne "") {
		$self->{_BTFidLen} = $1;
	    }
	    if ($2 ne "") {
		$self->{_BTFposLen} = $2;
	    }
	    if ($3 ne "") {
		$self->{_BTFlenLen} = $3;
	    }
	}
	$self->{_BTFpath} = $path;
	$self->{_BTFkill} = 0;
    } else {
	$self->{_BTFpath} = tmpnam() . $ext;
	$self->{_BTFpath} =~ s,^/var,,; # Get rid of /var (if needed...)
	$self->{_BTFkill} = 1;
    }
    if (defined $dPath) {
	$self->{_BTFdPath} = $dPath;
    }
    $self->{_BTFfile} = undef;
    $self->{_BTFwFile} = undef;
    $self->{_BTFbuf} = undef;
    $self->{_BTFrpos} = undef;
    $self->{_BTFrlen} = undef;
    $self->{_BTFnrpos} = undef;
    $self->{_BTFcmdtimeo} = 600;
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    if (defined $self->{_BTFfile}) {
	close $self->{_BTFfile};
    }
    if ($self->{_BTFkill} == 1) {
	unlink $self->{_BTFpath};
    }
}

sub unlink {
    my $self = shift;
    if (defined $self->{_BTFfile}) {
	close $self->{_BTFfile};
    }
    unlink $self->{_BTFpath};
}

sub killFile {
    my $self = shift;
    if (@_) {
	$self->{_BTFkill} = shift;
    }
    return $self->{_BTFkill};
}

sub openStream {
    my $self = shift;
    my $path = $self->{_BTFpath};
    if (defined $self->{_BTFfile}) {
	close $self->{_BTFfile};
    }
    $self->{_BTFfile} = undef;
    $self->{_BTFbuf} = undef;
    my $FH = gensym;
    if (!(open $FH, $path)) {
	warn "Could not open source \"$path\": $!";
	return;
    }
    $self->{_BTFfile} = $FH;
    $self->{_BTFrpos} = 0;
    $self->{_BTFrlen} = undef;
    $self->{_BTFnrpos} = 0;
}

sub getNext {
    my ($self, $mStart, $warn, $skip, $mStop, $inc) = @_;
    my $f = $self->{_BTFfile};
    if (! defined $f) {
	warn "Stream is not opened";
	return undef;
    }
    if (!defined $self->{_BTFbuf}) {
	$self->{_BTFbuf} = <$f>;
    }
    my $str = $self->{_BTFbuf};
    if ($skip == 1) {
	while (defined $str && !($str =~ /$mStart/)) {
	    if (defined $warn) {
		warn "$warn: $str";
	    }
	    # Move starting offset.
	    $self->{_BTFnrpos} += length $str;
	    $self->{_BTFbuf} = <$f>;
	    $str = $self->{_BTFbuf};
	}
	return undef unless defined $str;
    }
    # Set starting offset
    $self->{_BTFrpos} = $self->{_BTFnrpos};
    $self->{_BTFbuf} = <$f>;
    # Keep track of line length.  Signal if it varies.
    my $curLen = length $self->{_BTFbuf};
    $self->{_BTFvarLen} = 0;
    while (defined $self->{_BTFbuf} && !($self->{_BTFbuf} =~ /$mStop/)) {
	if ($self->{_BTFvarLen} > 0) {
	    $self->{_BTFvarLen} += 1;
	} elsif ($curLen != length $self->{_BTFbuf}) {
	    $self->{_BTFvarLen} = 1;
	}
	$str .= $self->{_BTFbuf};
	$self->{_BTFbuf} = <$f>;
    }
    if ($inc == 1) {
	$str .= $self->{_BTFbuf};
	$self->{_BTFbuf} = undef;
    }
    # Set next starting offset
    $self->{_BTFrlen} = length $str;
    $self->{_BTFnrpos} += $self->{_BTFrlen};
    return undef unless defined $str;
    return \$str;
}

sub getReadOffset {
    my $self = shift;
    return $self->{_BTFrpos};
}

sub getReadLength {
    my $self = shift;
    return $self->{_BTFrlen};
}

sub getVaryingLength {
    my $self = shift;
    return $self->{_BTFvarLen};
}

sub getAppFH {
    my $self = shift;
    if (defined $self->{_BTFwFile}) {
	die "Attempted to have two writers";
    }
    my $path = $self->{_BTFpath};
    my $FH = gensym;
    if (!(open $FH, ">>$path")) {
	warn "Could not open destination \"$path\": $!";
	return;
    }
    $self->{_BTFwFile} = $FH;
    return $FH;
}

sub closeAppFH {
    my $self = shift;
    if (!defined $self->{_BTFwFile}) {
	warn "Close for no writer";
    }
    close $self->{_BTFwFile};
    $self->{_BTFwFile} = undef;
}

sub existsP {
    my ($self, $id) = @_;
    my $path = $self->{_BTFpath};
    if ($path =~ /\.ptr$/) {
	return $self->fetchPtr($id, 1);
    }
    if ($path =~ /\.idx$/) {
	return $self->fetchIdx($id, 1);
    }
    warn "ExistsP unimplemented on index $path";
    return undef;
}

sub fetch {
    my $self = shift;
    my $path = $self->{_BTFpath};
    setlocale(LC_COLLATE, "POSIX");
    if ($path =~ /\.ptr$/) {
	return $self->fetchPtr(@_);
    }
    if ($path =~ /\.idx$/) {
	return $self->fetchIdx(@_);
    }
    warn "Fetch unimplemented on index $path";
    return undef;
}

sub fetchPtr {
    my ($self, $id, $onlyCheck, $multi, $minPos, $maxPos) = @_;
    my $ll = 64;
    my $headLen = $ll * 8;
    if (! -f $self->{_BTFpath}) {
	warn "Index file $self->{_BTFpath} not found";
	return undef;
    }
    my @status = stat($self->{_BTFpath});
    my $iSize = $status[7] - $headLen;
    my $FH = gensym;
    sysopen $FH, $self->{_BTFpath}, O_RDONLY;
    sysseek $FH, $ll, SEEK_SET;
    my $s;
    sysread $FH, $s, $ll;
    my ($base) = $s =~ /^ 2\. DIR=(.*)/;
    $base =~ s/\s+$//;
    # Get the file extension
    sysseek $FH, $ll * 2, SEEK_SET;
    sysread $FH, $s, $ll;
    my ($ext) = $s =~ /^ 3\. SEQ=\s*(\S+)/;
    # Get the key length
    sysseek $FH, $ll * 5, SEEK_SET;
    sysread $FH, $s, $ll;
    my ($keyL) = $s =~ /^ 6\. KLN=\s*(\d+)/;
    my $dirL = 32 - $keyL;
    # Prepare for the dichotomy search.
    my $bot = 0;
    my $top = $iSize;
    my $cur = $iSize / 2;
    if ($cur % $ll != 0) {
	$cur -= 32;
    }
    sysseek $FH, $cur + $headLen, SEEK_SET;
    sysread $FH, $s, $ll;
    my ($name) = $s =~ /^(\S{1,$keyL})/;
    $id =~ tr/a-z/A-Z/;
    while ($name ne $id) {
	if ($id gt $name) {
	    $bot = $cur + $ll;
	} else {
	    $top = $cur - $ll;
	}
	last if $bot > $top;
	$cur = ($top - $bot) / 2;
	if ($cur % $ll != 0) {
	    $cur -= 32;
	}
	$cur += $bot;
	sysseek $FH, $cur + $headLen, SEEK_SET;
	sysread $FH, $s, $ll;
	($name) = $s =~ /^(\S{1,$keyL})/;
    }
    close $FH;
    if ($name ne $id) {
	return undef;
    }
    return 1 if defined $onlyCheck;
    my $f = substr $s, $keyL, $dirL;
    my $seqlen = substr $s, 32, 10;
    my $seqpos = substr $s, 42, 9;
    my $pos = substr $s, 51, 12;
    $f =~ s/\s+$//;
    $seqlen =~ s/^\s+//;
    $seqpos =~ s/^\s+//;
    $pos =~ s/^\s+//;
    unless (-r "$base$f$ext") {
      warn "Can't read file $base$f$ext\n";
      return undef;
    }
    open $FH, "$base$f$ext";
    seek $FH, $pos + $seqpos, SEEK_SET;
    $s = <$FH>;
    close $FH;
    if ($seqlen > 200 && $s =~ /^ /) {
      $ll = length $s;
      $s =~ s/[\s\d]+//g;
      my $sl = length $s;
      my $nbl = int($seqlen / $sl);
      if (defined $minPos) {
	# minPos and maxPos start at 1
	$minPos -= 1;
	$maxPos -= 1;
	sysopen $FH, "$base$f$ext", O_RDONLY;
	sysseek $FH, $pos, SEEK_SET;
	sysread $FH, $s, $seqpos;
	my $fl = int($minPos / $sl);
	$minPos = $fl * $sl;
	sysseek $FH, $pos + $seqpos + $fl * $ll, SEEK_SET;
	my $el = int($maxPos / $sl) + 1;
	my $seq;
	if ($el <= $nbl) {
	  sysread $FH, $seq, ($el - $fl) * $ll;
	  $s .= $seq . "//\n";
	} else {
	  sysread $FH, $seq, ($nbl - $fl) * $ll;
	  close $FH;
	  $s .= $seq;
	  open $FH, "$base$f$ext";
	  seek $FH, $pos + $seqpos + $nbl * $ll, SEEK_SET;
	  while ( <$FH> ) {
	    last if $_ =~ /^>/;
	    $s .= $_;
	    last if $_ eq "//\n";
	  }
	}
	close $FH;
      } else {
	sysopen $FH, "$base$f$ext", O_RDONLY;
	sysseek $FH, $pos, SEEK_SET;
	sysread $FH, $s, $seqpos + $nbl * $ll;
	close $FH;
	open $FH, "$base$f$ext";
	seek $FH, $pos + $seqpos + $nbl * $ll, SEEK_SET;
	while ( <$FH> ) {
	  last if $_ =~ /^>/;
	  $s .= $_;
	  last if $_ eq "//\n";
	}
	close $FH;
      }
    } else {
      $minPos = 0 if defined $minPos;
      sysopen $FH, "$base$f$ext", O_RDONLY;
      sysseek $FH, $pos, SEEK_SET;
      sysread $FH, $s, $seqpos;
      close $FH;
      open $FH, "$base$f$ext";
      seek $FH, $pos + $seqpos, SEEK_SET;
      my $line;
      while (defined ($line = <$FH>)) {
	last if $line =~ /^>/;
	$s .= $line;
	last if $line eq "//\n";
      }
      close $FH;
    }
    if (defined $multi) {
	my @res = ($s);
	return \@res;
    }
    if (defined $minPos) {
	return ($minPos, $s);
    }
    return $s;
}

sub fetchIdx {
    my ($self, $id, $onlyCheck, $multi, $minPos, $maxPos) = @_;
    $id =~ tr/./_/;
    $id =~ tr/-/_/;
    $id =~ tr/a-z/A-Z/;
    my $idLen = $self->{_BTFidLen};
    my $packer = "A$idLen A$self->{_BTFposLen} A$self->{_BTFlenLen}";
    my $ll = $self->{_BTFidLen} + $self->{_BTFposLen} + $self->{_BTFlenLen} + 1;
    my $hll = int($ll / 2);;
    if (! -f $self->{_BTFpath}) {
	warn "Index file $self->{_BTFpath} not found";
	return undef;
    }
    my @status = stat($self->{_BTFpath});
    my $iSize = $status[7];
    my $FH = gensym;
    sysopen $FH, $self->{_BTFpath}, O_RDONLY;
    # Prepare for the dichotomy search.
    my $bot = 0;
    my $top = $iSize;
    my $cur = int($iSize / 2);
    if ($cur % $ll != 0) {
	$cur -= $hll;
    }
    my $s;
    sysseek $FH, $cur, SEEK_SET;
    sysread $FH, $s, $ll;
    my $name = substr $s, 0, $idLen;
    $name =~ s/\s+$//;
    while ($name ne $id) {
	if ($id gt $name) {
	    $bot = $cur + $ll;
	} else {
	    $top = $cur - $ll;
	}
	last if $bot > $top;
	$cur = int(($top - $bot) / 2);
	if ($cur % $ll != 0) {
	    $cur -= $hll;
	}
	$cur += $bot;
	sysseek $FH, $cur, SEEK_SET;
	sysread $FH, $s, $ll;
	$name = substr $s, 0, $idLen;
	$name =~ s/\s+$//;
    }
    if ($name ne $id) {
	close $FH;
	return undef;
    }
    if (defined $onlyCheck) {
	close $FH;
	return 1;
    }
    if (defined $multi) {
	my $prev = $cur - $ll;
	while ($prev >= 0) {
	    sysseek $FH, $prev, SEEK_SET;
	    sysread $FH, $s, $ll;
	    $name = substr $s, 0, $idLen;
	    $name =~ s/\s+$//;
	    last if $name ne $id;
	    $cur = $prev;
	    $prev -= $ll;
	}
	# We now have the first.  Grab them all.
	my @res;
	my ($begin, $len);
	my $DFH = gensym;
	sysopen $DFH, $self->{_BTFdPath}, O_RDONLY
	    or warn "Couldn't open file $self->{_BTFdPath}: $!\n";
	while ($cur < $iSize) {
	    sysseek $FH, $cur, SEEK_SET;
	    sysread $FH, $s, $ll;
	    ($name, $begin, $len) = unpack ($packer,$s);
	    $name =~ s/\s+$//;
	    last if $name ne $id;
	    sysseek $DFH, $begin, SEEK_SET;
	    sysread $DFH, $s, $len;
	    push @res, $s;
	    $cur += $ll;
	}
	close $DFH;
	close $FH;
	return \@res;
    }
    close $FH;
    unless (-r $self->{_BTFdPath}) {
      warn "Can't read file $self->{_BTFdPath}\n";
      return undef;
    }
    my ($begin, $len);
    ($name, $begin, $len) = unpack ($packer,$s);
    if (defined($minPos) && $len > 1000000) {
	open $FH, $self->{_BTFdPath};
	seek $FH, $begin, SEEK_SET;
	$s = <$FH>;
	if ($s !~ /^>/) {
	  close $FH;
	  sysopen $FH, $self->{_BTFdPath}, O_RDONLY;
	  sysseek $FH, $begin, SEEK_SET;
	  sysread $FH, $s, $len;
	  close $FH;
	  return (0, $s);
	}
	my $l1n = length $s;
	my $t = <$FH>;
	close $FH;
	my $l2n = length $t;
	$t =~ s/[\s\d]+//g;
	my $dl = length $t;
	# minPos and maxPos start at 1
	$minPos -= 1;
	$maxPos -= 1;
	my $lStart = int($minPos / $dl);
	$minPos = $lStart * $dl;
	$lStart = $lStart * $l2n + $l1n;
	if ($lStart >= $len) {
	    close $FH;
	    return (0, $s);
	}
	my $lEnd = int($maxPos / $dl) + 1;
	$lEnd = $lEnd * $l2n + $l1n;
	$lEnd = $len if $lEnd > $len;
	sysopen $FH, $self->{_BTFdPath}, O_RDONLY;
	sysseek $FH, $begin + $lStart, SEEK_SET;
	sysread $FH, $t, $lEnd - $lStart;
	close $FH;
	$s .= $t;
    } else {
	$minPos = 0 if defined $minPos;
	sysopen $FH, $self->{_BTFdPath}, O_RDONLY;
	sysseek $FH, $begin, SEEK_SET;
	sysread $FH, $s, $len;
	close $FH;
    }
    if (defined $minPos) {
	return ($minPos, $s);
    }
    return $s;
}

sub fetchCRC {
    my ($self, $id, $onlyCheck) = @_;
    my $packer = "A17 A44 A10 A6";
    my $ll = 78;
    my $hll = 39;
    if (! -f $self->{_BTFpath}) {
	warn "Index file $self->{_BTFpath} not found";
	return undef;
    }
    my @status = stat($self->{_BTFpath});
    my $iSize = $status[7];
    my $FH = gensym;
    sysopen $FH, $self->{_BTFpath}, O_RDONLY;
    # Prepare for the dichotomy search.
    my $bot = 0;
    my $top = $iSize;
    my $cur = int($iSize / 2);
    if ($cur % $ll != 0) {
	$cur -= $hll;
    }
    my $s;
    sysseek $FH, $cur, SEEK_SET;
    sysread $FH, $s, $ll;
    my ($crc) = $s =~ /^(\S{1,16})/;
    while ($crc ne $id) {
	if ($id gt $crc) {
	    $bot = $cur + $ll;
	} else {
	    $top = $cur - $ll;
	}
	last if $bot > $top;
	$cur = int(($top - $bot) / 2);
	if ($cur % $ll != 0) {
	    $cur -= $hll;
	}
	$cur += $bot;
	sysseek $FH, $cur, SEEK_SET;
	sysread $FH, $s, $ll;
	($crc) = $s =~ /^(\S{1,16})/;
    }
    if ($crc ne $id) {
	close $FH;
	return undef;
    }
    if (defined $onlyCheck) {
	close $FH;
	return 1;
    }
    # Ok, we have one.  There may be many, so go to the first.
    my $prev = $cur - $ll;
    while ($prev >= 0) {
	sysseek $FH, $prev, SEEK_SET;
	sysread $FH, $s, $ll;
	($crc) = $s =~ /^(\S{1,16})/;
	last if $crc ne $id;
	$cur = $prev;
	$prev -= $ll;
    }
    # We now have the first.  Grab them all.
    my @res;
    my ($file, $begin, $len);
    my $DFH = gensym;
    while ($cur < $iSize) {
	sysseek $FH, $cur, SEEK_SET;
	sysread $FH, $s, $ll;
	($crc, $file, $begin, $len) = unpack ($packer, $s);
	$crc =~ s/\s+$//;
	last if $crc ne $id;
	if (sysopen $DFH, $file, O_RDONLY) {
	    sysseek $DFH, $begin, SEEK_SET;
	    sysread $DFH, $s, $len;
	    close $DFH;
	    push @res, $s;
	} else {
	    warn "Couldn't open file $file: $!\n";
	}
	$cur += $ll;
    }
    close $FH;
    return \@res;
}

sub runCommand {
    my ($self, $preCmd, $postCmd) = @_;
    local *IN;
    local *OUT;
    local *ERR;
    # Get rid of stderr...
    open ERR, ">/dev/null";
    my $pid = open3(\*IN, \*OUT, '>&ERR', "$preCmd $self->{_BTFpath} $postCmd");
    close IN;
    close ERR;
    undef $/;
    eval {
      local $SIG{ALRM} = sub { die "GOT TIRED OF WAITING\n"; };
      alarm ($self->{_BTFcmdtimeo});
      $self->{_res} = <OUT>;
      alarm (0);
    };
    if ($@ =~ /GOT TIRED OF WAITING/) {
      print STDERR "Timed out($self->{_BTFcmdtimeo}): ",
	"$preCmd $self->{_BTFpath} $postCmd\n";
      kill 15, $pid;
      sleep 3;
      kill 9, $pid;
    }
    close OUT;
    $/ = "\n";
    waitpid $pid, 0;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
