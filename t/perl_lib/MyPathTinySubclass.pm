#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Boring subclass of Path::Tiny::Inheritable for testing purposes
#####################################################################

package MyPathTinySubclass;

use strict;
use warnings;

use parent qw(Path::Tiny::Inheritable);

use parent qw(Exporter);
our @EXPORT = qw(path);
our @EXPORT_OK = qw(
    cwd
    rootdir
    tempfile
    tempdir
);

sub path {
    __PACKAGE__->new(@_);
}

sub cwd {
    __PACKAGE__->SUPER::cwd;
}

sub rootdir {
    __PACKAGE__->SUPER::rootdir;
}

sub tempfile {
    my $class = $_[0] eq __PACKAGE__ ? shift : __PACKAGE__;
    $class->SUPER::tempfile(@_);
}

sub tempdir {
    my $class = $_[0] eq __PACKAGE__ ? shift : __PACKAGE__;
    $class->SUPER::tempdir(@_);
}

1;
