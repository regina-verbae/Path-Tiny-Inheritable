use 5.008001;
use strict;
use warnings;
use Cwd; # hack around https://bugs.activestate.com/show_bug.cgi?id=104767
use Test::More 0.96;
use File::Spec::Unix;

use lib 't/lib';
use TestUtils qw/exception tempd/;

 use Path::Tiny::Inheritable;

subtest "tempdir" => sub {
    my $tempdir = Path::Tiny::Inheritable->tempdir;
    my $string  = $tempdir->stringify;
    ok( $tempdir->exists, "tempdir exists" );
    undef $tempdir;
    ok( !-e $string, "tempdir destroyed" );
};

subtest "tempfile" => sub {
    my $tempfile = Path::Tiny::Inheritable->tempfile;
    my $string   = $tempfile->stringify;
    ok( $tempfile->exists, "tempfile exists" );
    undef $tempfile;
    ok( !-e $string, "tempfile destroyed" );
};

subtest "tempdir w/ TEMPLATE" => sub {
    my $tempdir = Path::Tiny::Inheritable->tempdir( TEMPLATE => "helloXXXXX" );
    like( $tempdir, qr/hello/, "found template" );
};

subtest "tempfile w/ TEMPLATE" => sub {
    my $tempfile = Path::Tiny::Inheritable->tempfile( TEMPLATE => "helloXXXXX" );
    like( $tempfile, qr/hello/, "found template" );
};

subtest "tempdir w/ leading template" => sub {
    my $tempdir = Path::Tiny::Inheritable->tempdir("helloXXXXX");
    like( $tempdir, qr/hello/, "found template" );
};

subtest "tempfile w/ leading template" => sub {
    my $tempfile = Path::Tiny::Inheritable->tempfile("helloXXXXX");
    like( $tempfile, qr/hello/, "found template" );
};

subtest "tempfile handle" => sub {
    my $tempfile = Path::Tiny::Inheritable->tempfile;
    my $fh       = $tempfile->filehandle;
    is( ref $tempfile->[5],    'File::Temp', "cached File::Temp object" );
    is( fileno $tempfile->[5], undef,        "cached handle is closed" );
};

subtest "survives absolute" => sub {
    my $wd = tempd;
    my $tempdir = Path::Tiny::Inheritable->tempdir( DIR => '.' )->absolute;
    ok( -d $tempdir, "exists" );
};

done_testing;
# COPYRIGHT

### Test automatically generated from the Path::Tiny test