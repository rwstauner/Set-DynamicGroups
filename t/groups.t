use strict;
use warnings;
use Test::More;

my $mod = 'Set::DynamicGroups';
require_ok($mod);

my $set = $mod->new;
isa_ok($set, $mod);

$set->append(g1 => 'm1');
is_deeply($set->groups, {g1 => [qw(m1   )]}, 'group appended string');

$set->append(g1 => ['m2']);
is_deeply($set->groups, {g1 => [qw(m1 m2)]}, 'group appended array');

$set->set(g1 => [qw(m2 m3)]);
is_deeply($set->groups, {g1 => [qw(m2 m3)]}, 'group reset');

$set->append(g2 => {items => [qw(m5 m6)]});
is_deeply($set->groups, {g1 => [qw(m2 m3)], g2 => [qw(m5 m6)]}, 'add group');

$set->append(g2 => {items => [qw(m5)]});
is_deeply($set->groups, {g1 => [qw(m2 m3)], g2 => [qw(m5 m6)]}, 'ignore unique item');

$set->set(g1 => 'm2');
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'group reset');

$set->set(g1 => [qw(m2)]);
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'group reset');

$set->append(g1 => 'm2');
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'ignore unique item');

$set->append(g2 => [qw(m5 m6)]);
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)]}, 'ignore unique items');

is_deeply([sort @{$set->items}], [qw(m2 m5 m6)],       'all items');

done_testing;
