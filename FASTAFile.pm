# A FASTA file object.
package FASTAFile;

use strict;
use vars qw($VERSION @ISA);
use BTFile;
use FASTAEntry;

@ISA = qw(BTFile);
$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my ($proto, $path, $dPath, $idLen, $posLen, $lenLen) = @_;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new($path, ".fasta", $dPath,
				   $idLen, $posLen, $lenLen);
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
}

sub getNext {
    my $self = shift;
    my $strr = $self->SUPER::getNext("^>", "Junk in FASTA file", 1,
				     "^>", 0);
    return undef unless defined $strr;
    my $e = FASTAEntry->new;
    $e->parse($strr);
    return $e;
}

sub fetch {
    my ($self, $id) = @_;
    my $str = $self->SUPER::fetch($id);
    return undef unless defined $str;
    my $e = FASTAEntry->new;
    $e->parse(\$str);
    return $e;
}

sub fetchCRC {
    my ($self, $id) = @_;
    my @res;
    my $ar = $self->SUPER::fetchCRC($id);
    foreach my $str (@$ar) {
	my $e = FASTAEntry->new;
	$e->parse(\$str);
	push @res, $e;
    }
    return \@res;
}

sub appendSeq {
    my ($self, $seq, $w) = @_;
    my $FH = $self->getAppFH;
    $seq->printFASTA($FH, $w);
    $self->closeAppFH;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
