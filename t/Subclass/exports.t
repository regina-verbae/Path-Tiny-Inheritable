use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

use lib 't/perl_lib'; use MyPathTinySubclass qw/path cwd rootdir tempdir tempfile/;

isa_ok( path("."), 'MyPathTinySubclass', 'path' );
isa_ok( cwd,       'MyPathTinySubclass', 'cwd' );
isa_ok( rootdir,   'MyPathTinySubclass', 'rootdir' );
isa_ok( tempfile( TEMPLATE => 'tempXXXXXXX' ), 'MyPathTinySubclass', 'tempfile' );
isa_ok( tempdir( TEMPLATE => 'tempXXXXXXX' ), 'MyPathTinySubclass', 'tempdir' );

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:

### Test automatically generated from the Path::Tiny test