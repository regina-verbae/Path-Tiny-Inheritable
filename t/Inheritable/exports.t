use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

 use Path::Tiny::Inheritable qw/path cwd rootdir tempdir tempfile/;

isa_ok( path("."), 'Path::Tiny::Inheritable', 'path' );
isa_ok( cwd,       'Path::Tiny::Inheritable', 'cwd' );
isa_ok( rootdir,   'Path::Tiny::Inheritable', 'rootdir' );
isa_ok( tempfile( TEMPLATE => 'tempXXXXXXX' ), 'Path::Tiny::Inheritable', 'tempfile' );
isa_ok( tempdir( TEMPLATE => 'tempXXXXXXX' ), 'Path::Tiny::Inheritable', 'tempdir' );

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:

### Test automatically generated from the Path::Tiny test