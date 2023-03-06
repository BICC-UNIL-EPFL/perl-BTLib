# A SwissPROT file object.
package SPFile;

use strict;
use vars qw($VERSION @ISA);
use BTFile;
use SPEntry;

@ISA = qw(BTFile);
$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my ($proto, $path, $dPath, $idLen, $posLen, $lenLen) = @_;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new($path, ".sp", $dPath, $idLen, $posLen, $lenLen);
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
}

sub getNext {
    my $self = shift;
    my $strr = $self->SUPER::getNext("^ID ", "Junk in SwissPROT file", 1,
				     "^//", 1);
    return undef unless defined $strr;
    my $e = SPEntry->new;
    $e->parse($strr);
    return $e;
}

sub appendSeq {
    my ($self, $seq, $w) = @_;
    my $FH = $self->getAppFH;
    $seq->printSP($FH, $w);
    $self->closeAppFH;
}

sub fetch {
    my ($self, $id) = @_;
    my $strr = $self->SUPER::fetch($id);
    return undef unless defined $strr;
    my $sp = SPEntry->new;
    $sp->parse(\$strr);
    return $sp;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
