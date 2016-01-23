use strict;
use warnings;

use Test::More tests => 3;

use lib 't/perl_lib'; use MyPathTinySubclass;

path('t/Subclass')->visit(sub{ return [ ] });

pass "visit callback doesn't choke on random returned refs";

my $all;
my $terminated;

path('t/Subclass')->visit(sub{ $all++ });

path('t/Subclass')->visit(sub{ $terminated++; return \0 if $terminated == 10 });

is $terminated => 10, "terminated before the whole dir was read";

cmp_ok $all, '>=', $terminated, "we have more than 10 tests in that dir";


### Test automatically generated from the Path::Tiny test