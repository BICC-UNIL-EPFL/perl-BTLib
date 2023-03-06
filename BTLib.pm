package BTLib;

# We define an object that can contain a sequence and apply various
# tools to said sequence.
#  - seq: the sequence as a string.
#  - seqHead: the FASTA header line.
#  - seqFile: the file name of the FASTA formatted sequence.
#  - killFile: 1 if the FASTA sequence file should be deleted when the
#    object is destroyed, 0 otherwise.

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = "0.23";

bootstrap BTLib $VERSION;

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    $self->{_seq} = undef;
    $self->{_seqHead} = undef;
    $self->{_seqFile} = undef;
    $self->{_killFile} = 1;
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
#    warn "DESTROYING $self";
    if ($self->{_killFile} == 1 && defined $self->{_seqFile}) {
#	warn "unlink $self->{_seqFile}";
	unlink $self->{_seqFile};
    }
}

# methods to access per-object data
#
# With args, they set the value.  Without any, they only retrieve
# it/them.

sub seq {
    my $self = shift;
    if (@_) {
	# Cleanup the sequence.
	$self->{_seq} = shift;
	$self->{_seq} =~ tr/a-z/A-Z/;
	$self->{_seq} =~ s/[^A-Z]+//g;
    }
    return $self->{_seq};
}

sub seqLength {
    my $self = shift;
    return length $self->{_seq};
}

sub seqHead {
    my $self = shift;
    if (@_) {
	$self->{_seqHead} = shift;
    }
    return $self->{_seqHead};
}

sub seqFile {
    my $self = shift;
    if (@_) {
	# If we receive a file, do not automatically unlink it.
	$self->{_seqFile} = shift;
	$self->{_killFile} = 0;
    }
    return $self->{_seqFile};
}

sub killFile {
    my $self = shift;
    if (@_) {
	$self->{_killFile} = shift;
    }
    return $self->{_killFile};
}

# Remove leading and trailing Ns
sub trimNs {
    my $self = shift;
    $self->{_seq} =~ s/^N+//;
    $self->{_seq} =~ s/N+$//;
}

# Print the sequence in FASTA format.
sub printFASTA {
    my ($self, $out, $w) = @_;
    $w = 80 unless defined $w;

    my $seq = $self->{_seq};
    $seq =~ s/(.{$w})/$1\n/g;
    $seq =~ s/\s+$//; # remove a trailing newline, since we add one below.
    print $out "$self->{_seqHead}\n";
    print $out "$seq\n";
}

# Ensures that the sequence is in a file.
sub seqToFile {
    my $self = shift;

    if (defined $self->{_seqFile}) {
	return;
    }
    unless (defined $self->{_seqHead} && defined $self->{_seq}) {
	warn "header and/or sequence are undefined";
	return;
    }
    use File::Temp qw/ :POSIX /;
    $self->{_seqFile} = tmpnam();
    $self->{_seqFile} =~ s,^/var,,; # Get rid of /var (if needed...)
    use Symbol;
    my $FH = gensym;
    open $FH, ">$self->{_seqFile}";
    $self->printFASTA($FH);
    close $FH;
}

# Ensures that the sequence is in a string.
# (A bit of a misnomer... oh well.
sub fileToSeq {
    my $self = shift;

    if (defined $self->{_seq}) {
	return;
    }
    unless (defined $self->{_seqFile}) {
	warn "sequence filename is undefined";
	return;
    }
    $self->{_seq} = "";
    local *SEQ;
    open SEQ, "$self->{_seqFile}";
    $self->{_seqHead} = <SEQ>;
    $self->{_seqHead} =~ s/\s*$//; # Remove trailing blanks and newline
    my $line;
    while (defined($line = <SEQ>)) {
	$line =~ s/\s*$//;
	$line =~ tr/a-z/A-Z/;
	$self->{_seq} .= $line;
    }
    close SEQ;
}

# Apply a filter to the sequence, and return a new sequence.
sub filterSeq {
    my ($self, $command) = @_;
    $self->seqToFile;
    local *OUT;
    open OUT, "$command $self->{_seqFile} 2>/dev/null |"
	or die "Can't filter $command: $!";
    my $fhead = <OUT>;
    $fhead =~ s/\s*$//; # Remove trailing blanks and newline
    my $fseq = "";
    my $line;
    while (defined($line = <OUT>)) {
	$line =~ s/\s*$//;
	$line =~ tr/a-z/A-Z/;
	$fseq .= $line;
    }
    close OUT;
    my $nseq = BTLib->new;
    $nseq->seqHead($fhead);
    $nseq->seq($fseq);
    return $nseq;
}

sub revComp {
    my ($self) = @_;
    $self->fileToSeq;
    my $nseq = BTLib->new;
    my $head = $self->seqHead . "; minus strand";
    my $seq = $self->seq;
    $seq =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZ/TVGHNNCDNNMNKNNNNYSAABWNRN/;
    $seq = reverse $seq;
    $nseq->seqHead($head);
    $nseq->seq($seq);
    return $nseq;
}

sub toProt {
    my ($self) = @_;
    $self->fileToSeq;
    my $nseq = BTLib->new;
    my $head = $self->seqHead . "; translated";
    my $seq = na2aa($self->{_seq});
    $nseq->seqHead($head);
    $nseq->seq($seq);
    return $nseq;
}

# This routine calculates the CRC of the sequence using the table
# lookup method.
sub crc32 {
    my $self = shift;
    return SPcrc32($self->{_seq});
}

# A more robust CRC.
sub crc64 {
    my $self = shift;
    return SPcrc64($self->{_seq});
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

BTLib - Perl extension for a Biology Toolkit Library.

=head1 SYNOPSIS

  use BTLib;

  Object creation:
  new

  Component access:
  seq
  seq (sequence)
  seqHead
  seqHead (fasta_header)
  seqFile
  seqFile (filename)
  killFile
  killFile (boolean)

  Methods:
  filterSeq (command)

  Internal methods:
  DESTROY
  seqToFile
  fileToSeq

=head1 DESCRIPTION

BTLib offers an interface to apply various tools (like blast, the FDF
or the pftools) to analyze a protein or DNA sequence.

The basic concept is that a sequence to analyze is represented by an
object of type BTLib.  You create this object using the method new().
The newly created objects has all its fields set to undefined.  For
example:
    $main::seq = BTLib->new;

The next step is to provide a sequence to the new object.  This can be
done in two ways: either provide the name of a file containing a FASTA
formatted sequence using the method seqFile(), or provide the sequence
header and the sequence itself using the methods seqHead() and seq()
respectively.  So we have either:
    $main::seq->seqFile("/tmp/my.seq");

or:
    $main::seq->seqHead(">emb|AB000095|AB000095 ...");
    $main::seq->seq("CGGCCGAGCCCAGCTCTCCGAG...");

The sequence can be filtered, using an arbitrary Unix command that
writes its results to standard output, using the method filterSeq().
This generates a new sequence object.  Thus you can say:
    my $filteredSeq = $main::seq->filterSeq("xnu");

If you no longer need the original sequence, you can also write:
    $main::seq = $main::seq->filterSeq("xnu");

The object takes care (automagicaly) of creating a temporary FASTA
file containing the sequence, if needed.  The file is deleted when the
object dies.  When a file is supplied to the object, it will not be
deleted, unless you call the killFile() method with a non-zero
parameter.

=head1 AUTHOR

Christian Iseli

=head1 SEE ALSO

perl(1).

=cut
