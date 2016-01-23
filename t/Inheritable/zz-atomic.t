use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

BEGIN {
    plan skip_all => "Can't mock random() with Path::Tiny already loaded"
      if $INC{'Path/Tiny/Inheritable.pm'};
    eval "use Test::MockRandom 'Path::Tiny::Inheritable';";
    plan skip_all => "Test::MockRandom required for atomicity tests" if $@;
}

use lib 't/lib';
use TestUtils qw/exception/;

 use Path::Tiny::Inheritable;
srand(0);

subtest "spew (atomic)" => sub {
    my $file = Path::Tiny::Inheritable->tempfile;
    ok( $file->spew("original"), "spew" );
    is( $file->slurp, "original", "original file" );

    my $tmp = $file->[Path::Tiny::PATH] . $$ . "0";
    open my $fh, ">", $tmp;
    ok( $fh, "opened collision file '$tmp'" );
    print $fh "collide!";
    close $fh;

    my $error = exception { ok( $file->spew("overwritten"), "spew" ) };
    ok( $error, "spew errors if the temp file exists" );
    is( $file->slurp(), "original", "original file intact" );
};

done_testing();

### Test automatically generated from the Path::Tiny test