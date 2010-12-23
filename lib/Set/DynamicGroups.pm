package Set::DynamicGroups;
# ABSTRACT: Manage groups of items dynamically

=head1 SYNOPSIS

	use Set::DynamicGroups;

	my $set = Set::DynamicGroups->new();
	$set->append(group_name => 'member1');

=cut

use strict;
use warnings;
use Carp qw(croak);

our %Aliases = (
	not_in  => 'exclude_groups',
	in      => 'include_groups',
	items   => 'include',
	members => 'include',
	not     => 'exclude',
);

=method new

Constructor.

Takes no arguments.

=cut

sub new {
	my ($class) = @_;
	my $self = {
		groups => {},
	};
	bless $self, $class;
}

=method append

	$set->append(group_name => $group_spec);

Append items to the specified group.

=cut

sub append {
	my ($self) = shift;
	my %groups = ref $_[0] ? %{$_[0]} : @_;
	while( my ($name, $spec) = each %groups ){
		$spec = $self->normalize($spec);
		my $group = ($self->{groups}->{$name} ||= {});
		# could use Hash::Merge, but this is a simple case:
		while( my ($key, $val) = each %$spec ){
			$self->_push_unique(($group->{$key} ||= []), {}, @$val);
		}
	}
	return $self;
}

=method append_items
X<append_members>

Append the provided items to the full list of known items.
Arguments can be strings or array references (which will be flattened).

Aliased as C<append_members>.

=cut

sub append_items {
	my ($self, @append) = @_;

	my $items = ($self->{items} ||= []);
	$self->_push_unique($items, {}, map { ref $_ ? @$_ : $_ } @append);
	return scalar @$items;
}
*append_members = \&append_items;

sub _determine_items {
	my ($self, $name) = @_;

	# TODO: Disallow infinite recursion... use an option to say which group(s)
	# are currently in the stack?  Detect mutual dependence upon specification?
	# name is required (rathan than ref) to push name onto anti-recursion stack
	# push(@{ $self->{determining} ||= [] }, $name);
	# die("Infinite recursion detected on groups: @{ $self->{determining} }");

	# If the group doesn't exist just return an empty arrayref
	# rather than autovivifying and filling with the wrong items, etc.
	return []
		unless my $group = $self->{groups}{$name};

	my @exclude = @{ $self->_flatten_items($group, 'exclude') };

	# If no includes (only excludes) are specified,
	# populate the list with all known items.
	# Use _push_unique to maintain order (and uniqueness).
	my @include;
	$self->_push_unique(\@include, +{ map { $_ => 1 } @exclude }, @{
		(exists $group->{include} || exists $group->{include_groups})
		? $self->_flatten_items($group, 'include')
		: $self->items
	});

	return \@include;
}

sub _flatten_items {
	my ($self, $group, $which) = @_;
	my @items = @{ $group->{ $which } || [] };
	if( my $items = $group->{ "${which}_groups" } ){
		my @flat = map { @{ $self->_determine_items($_) } } @$items;
		push(@items, @flat);
	}
	return \@items;
}

=method groups

	$set->groups(); # returns {groupname => \@items, ...}
	$set->groups(@group_names);

Return a hashref of each group and the items contained.

Sending a list of group names will
restrict the hashref to just those groups (instead of all).

The keys are group names and the values are arrayrefs of items.

=cut

sub groups {
	my ($self, @names) = @_;
	my %groups;
	my %group_specs = %{$self->{groups}};

	# if names provided, limit to those (and flatten), otherwise do all
	@names = @names
		? map { ref $_ ? @$_ : $_ } @names
		: keys %group_specs;

	foreach my $name ( @names ){
		$groups{$name} = $self->_determine_items($name);
	}

	return \%groups;
}

=method items
X<members>

Return an arrayref of all known items.

Aliased as C<members>.

=cut

sub items {
	my ($self) = @_;
	# TODO: make it an option which things are included in this list?
	my @items = @{ $self->{items} || [] };
	# concatenate all items included in groups
	$self->_push_unique(\@items, {},
		map { @{ $_->{include} || [] } }
			values %{ $self->{groups} });
	return \@items;
}
*members = \&items;

=method normalize

Used internally to normalize group specifications.

See L</GROUP SPECIFICATION>.

=cut

sub normalize {
	my ($self, $spec) = @_;

	# if not a hashref, assume it's an (array of) item(s)
	$spec = {include => $spec}
		unless ref $spec eq 'HASH';

	# TODO: croak if any unrecognized keys are present

	while( my ($alias, $name) = each %Aliases ){
		if( exists($spec->{$alias}) ){
			croak("Cannot include both an option and its alias: " .
				"'$name' and '$alias' are mutually exclusive.")
					if exists $spec->{$name};
			$spec->{$name} = delete $spec->{$alias};
		}
	}

	while( my ($key, $value) = each %$spec ){
		# convert scalar (string) to arrayref
		$spec->{$key} = [$value]
			unless ref $value;
	}

	return $spec;
}

sub _push_unique {
	my ($self, $array, $seen, @push) = @_;

	# Ignore items already present.
	# List assignment on a hash slice benches faster than: ++$s{$_} for @a
	@$seen{ @$array } = (1) x @$array;

	push(@$array, grep { !$$seen{$_}++ } @push);
}

=method set

Set a group specification to the provided value
(resetting any previous specifications).

This is a shortcut for removing any previous specifications
and then calling L</append>().

=cut

sub set {
	my ($self) = shift;
	my %groups = ref $_[0] ? %{$_[0]} : @_;
	delete $self->{groups}{$_} foreach keys %groups;
	$self->append(%groups);
}

=method set_items
X<set_members>

Set the full list of items to the provided items.

This is a shortcut for removing any previous items
and then calling L</append_items>().

Aliased as C<set_members>.

=cut

sub set_items {
	my ($self) = shift;
	delete $self->{items};
	return $self->append_items(@_);
}
*set_members = \&set_items;

1;

=for stopwords arrayrefs TODO

=head1 DESCRIPTION

=head1 GROUP SPECIFICATION

A group specification can be in one of the following formats:

=begin :list

= I<scalar>
A single member;
This is converted to an arrayref with one element.

= I<arrayref>
An array of items.
This is converted into a hashref with the C<include> key.

= I<hashref>
Possible options:

=begin :list

= C<include> (or C<items> (or C<members>))
An arrayref of items to include in the group

= C<exclude> (or C<not>)
An arrayref of items to exclude from the group

= C<include_groups> (or C<in>)
An arrayref of groups whose items will be included

= C<exclude_groups> (or C<not>)
An arrayref of groups whose items will be excluded

=end :list

Each option can be a string which will be converted to
an arrayref with a single element.

=end :list

=head1 TODO

=for :list
* Cache the group calculations to avoid redundant processing?

=head1 RATIONALE

I searched for other "grouping" modules on CPAN
but found none that supported basing one group off of another.
Unsatisfied by the API of the modules I looked at,
I borrowed their namespace and created this implementation.

=head1 SEE ALSO

=for :list
* L<Set::Groups>
* L<Set::NestedGroups>

=cut
