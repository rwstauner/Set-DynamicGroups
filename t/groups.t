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

$set->set(g3 => {in => [qw(g1 g2)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m2 m5 m6)]}, 'include from group');

$set->set(g3 => {not_in => [qw(g1)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m5 m6)]}, 'exclude from group');

is_deeply($set->groups(qw(g2 g3)), {g2 => [qw(m5 m6)], g3 => [qw(m5 m6)]}, 'limit groups() by names');
is_deeply($set->groups(qw(g2)), {g2 => [qw(m5 m6)]}, 'limit groups() by names');
is_deeply($set->groups(qw(g1 g2 g3)), $set->groups, 'limit groups() by names');
is_deeply($set->groups('g2')->{g2}, [$set->group('g2')], 'group() matches groups()');
is_deeply([$set->group('g2')], [qw(m5 m6)], 'group() returns expected list');

is(eval { $set->group('idunno'); 1 }, undef, 'unknown group() dies');
like($@, qr/Group .+ is not defined/, 'unknown group() died with expected message');

is_deeply([sort @{$set->items}], [qw(m2 m5 m6)],       'all items');
$set->append_items(qw(m6 m7));
is_deeply([sort @{$set->items}], [qw(m2 m5 m6 m7)],    'all items (no duplicates)');
$set->append_items(qw(m6 m7 m8));
is_deeply([sort @{$set->items}], [qw(m2 m5 m6 m7 m8)], 'all items (no duplicates)');

$set->set(g3 => {in => [qw(g1 g2)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m2 m5 m6)]}, 'include from group');

$set->set(g3 => {not_in => [qw(g1)]});
# m5 is last b/c items come first (see append_items above)
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m7 m8 m5)]}, 'exclude from group');

$set->set_items(qw(m7));
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m7 m5 m6)]}, 'reset items and exclude from group');

$set->set_items(qw(m6));
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m5)]}, 'reset items and exclude from group');

# reference a group that doesn't exist
$set->set(g3 => {not_in => [qw(g1 g0)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m5)]}, 'exclude from group (ignore non-existent)');

$set->set(g4 => {in => [qw(g0)]});
is_deeply($set->groups, {g1 => [qw(m2)], g2 => [qw(m5 m6)], g3 => [qw(m6 m5)], g4 => []}, 'include from group (ignore non-existent)');

$set->set(g4 => {not_in => [qw(g0)]});
# I can't guarantee the order here, so sort it
is_deeply([sort @{$set->groups->{g4}}], [qw(m2 m5 m6)], 'include from group (ignore non-existent)');

done_testing;
