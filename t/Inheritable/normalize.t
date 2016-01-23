use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

 use Path::Tiny::Inheritable;

my @cases = (
#<<<
    [ '.'   => '.'  ],
    [ './'  => '.'  ],
    [ '/'   => '/'  ],
    [ '/.'  => '/'  ],
    [ '..'  => '..' ],
    [ '/..'  => '/' ],
    [ '../'  => '..' ],
    [ '../..'  => '../..' ],
    [ '/./'  => '/' ],
    [ '/foo/'  => '/foo' ],
    [ 'foo/'  => 'foo' ],
    [ './foo'  => 'foo' ],
    [ 'foo/.'  => 'foo' ],
#>>>
);

for my $c (@cases) {
    my ( $in, $out ) = @$c;
    my $label = defined($in) ? $in : "undef";
    $label = "empty" unless length $label;
    is( path($in)->stringify, $out, sprintf( "%5s -> %-5s", $label, $out ) );
}

done_testing;
# COPYRIGHT

### Test automatically generated from the Path::Tiny test