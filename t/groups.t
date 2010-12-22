use strict;
use warnings;
use Test::More;

my $mod = 'Set::DynamicGroups';
require_ok($mod);

my $set = $mod->new;
isa_ok($set, $mod);

$set->append(g1 => 'm1');
is_deeply($set->{groups}, {g1 => [qw(m1   )]}, 'group appended string');

$set->append(g1 => ['m2']);
is_deeply($set->{groups}, {g1 => [qw(m1 m2)]}, 'group appended array');

done_testing;
