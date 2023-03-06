# An EMBL file object.
package EMBLFile;

use strict;
use vars qw($VERSION @ISA);
use BTFile;
use EMBLEntry;

@ISA = qw(BTFile);
$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my ($proto, $path) = @_;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new($path, ".embl");
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
}

sub getNext {
    my $self = shift;
    my $strr = $self->SUPER::getNext("^ID ", "Junk in EMBL file", 1,
				     "^//", 1);
    return undef unless defined $strr;
    my $e = EMBLEntry->new;
    $e->parse($strr);
    return $e;
}

sub appendSeq {
    my ($self, $seq, $w) = @_;
    my $FH = $self->getAppFH;
    $seq->printEMBL($FH, $w);
    $self->closeAppFH;
}

sub fetch {
    my ($self, $id) = @_;
    my $strr = $self->SUPER::fetch($id);
    return undef unless defined $strr;
    my $embl = EMBLEntry->new;
    $embl->parse(\$strr);
    return $embl;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
