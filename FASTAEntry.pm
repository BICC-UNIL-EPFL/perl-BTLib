package FASTAEntry;

# We define an object that attempts to represent a FASTA entry.
# We expect the entry in the form:
#  >db|AC|ID [OS]DE

use strict;
use vars qw($VERSION @ISA);
use BTLib;

@ISA = qw(BTLib);
$VERSION = "0.23";

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = $class->SUPER::new();
    $self->{_FASTAdb} = undef;
    $self->{_FASTAac} = undef;
    $self->{_FASTAid} = undef;
    $self->{_FASTAos} = undef;
    $self->{_FASTAde} = undef;
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
}

sub ac {
    my $self = shift;
    if (@_) {
	$self->{_FASTAac} = shift;
    }
    return $self->{_FASTAac};
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{_FASTAid} = shift;
    }
    return $self->{_FASTAid};
}

sub parse {
    my ($self, $strr) = @_;
    # Get the ID line.
    my $l1len = index $$strr, "\n";
    my $s = substr $$strr, 0, $l1len;
    my ($db, $ac, $de) = $s =~
	/^>([^|]*)\|([^|\s;]*)(.*)/;
    my ($id, $os);
    if ($db =~ /^emb/) {
	($db, $ac, $id, $os, $de) = $s =~
	    /^>([^|]*)\|([^|]*)\|(\S+)[^[]*\[([^\]]*)](.*)/;
    }
    if ($db =~ /^ug/) {
	($db, $ac, $id, $de) = $s =~
	    /^>([^|]*)\|([^|]*)\|(\S*)(.*)/;
    }
    $id =~ s/\s+$//;
    $de =~ s/^\s+//;
    $de =~ s/\s+$//;
    $self->{_FASTAdb} = $db;
    $self->{_FASTAac} = $ac;
    $self->{_FASTAid} = $id;
    $self->{_FASTAos} = $os;
    $self->{_FASTAde} = $de;
    $self->seq(substr($$strr, $l1len + 1));
    $self->seqHead($s);
}

sub osMatch {
    my ($self, $name) = @_;
    my $i;
    $name = lc $name;
    $name =~ s/\W//g;
    my $s = $self->{_FASTAos};
    $s = lc $s;
    $s =~ s/\W//g;
    return 1 if ($name eq $s);
    return 0;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut
