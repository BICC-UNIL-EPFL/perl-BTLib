# A UniGene file object.
package UGFile;

use strict;
use vars qw($VERSION @ISA);
use BTFile;
use UGEntry;

@ISA = qw(BTFile);
$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my ($proto, $path, $dPath) = @_;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new($path, ".data", $dPath);
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
}

sub getNext {
    my $self = shift;
    my $strr = $self->SUPER::getNext("^ID ", undef, 1,
				     "^//", 1);
    return undef unless defined $strr;
    my $e = UGEntry->new;
    $e->parse($strr);
    return $e;
}

sub fetch {
    my ($self, $id) = @_;
    my $strr = $self->SUPER::fetch($id);
    return undef unless defined $strr;
    my $ug = UGEntry->new;
    $ug->parse(\$strr);
    return $ug;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
