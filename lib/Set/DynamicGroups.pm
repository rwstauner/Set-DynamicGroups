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

sub new {
	my ($class) = @_;
	my $self = {
		groups => {},
	};
	bless $self, $class;
}

my %spec_aliases = (
	not_in  => 'exclude_groups',
	in      => 'include_groups',
	items   => 'include',
	members => 'include',
	not     => 'exclude',
);

=method append

	$set->append(group_name => $group_spec);

Append members to the specified group.

=cut

sub append {
	my ($self) = shift;
	my %groups = ref $_[0] ? %{$_[0]} : @_;
	while( my ($name, $spec) = each %groups ){
		$spec = $self->normalize($spec);
		my $group = ($self->{groups}->{$name} ||= {});
		# could use Hash::Merge, but this is a simple case:
		while( my ($key, $val) = each %$spec ){
			push(@{$group->{$key} ||= []}, @$val);
		}
	}
	return $self;
}

=method determine_members
X<determine_items>

	$set->determine_members($group_name);

Return an array ref of the members for the specified group.

Used by L</groups> for each defined group.

This method is internal and shouldn't normally be used outside of this class,
but is aliased as C<determine_items> for consistency with other methods.

=cut

sub determine_members {
	my ($self, $name) = @_;

	# TODO: Disallow infinite recursion... use an option to say which group(s)
	# are currently in the stack?  Detect mutual dependence upon specification?
	# push(@{ $self->{determining} ||= [] }, $name);
	# die("Infinite recursion detected on groups: @{ $self->{determining} }");

	my $group = $self->{groups}{$name};
	# use hash for uniqueness and ease of removal
	my %members;

	# TODO: if only exclusions are specified, populate with all items first

	# add members
	if( my $items = $group->{include} ){
		@members{ @$items } = ();
	}

	if( my $include = $group->{include_groups} ){
		my @in = map { @{ $self->determine_members($_) } } @$include;
		@members{ @in } = ();
	}

	# remove members
	if( my $items = $group->{exclude} ){
		delete @members{ @$items };
	}

	if( my $exclude = $group->{exclude_groups} ){
		my @ex = map { @{ $self->determine_members($_) } } @$exclude;
		delete @members{ @ex };
	}

	return [keys %members];
}
*determine_items = \&determine_members;

=method groups

Return a hashref of each group and its members.

The keys are group names and the values are array refs of members
as returned by L</determine_members>.

=cut

sub groups {
	my ($self) = @_;
	my %groups;
	my %group_specs = %{$self->{groups}};

	while( my ($name, $spec) = each %group_specs ){
		$groups{$name} = $self->determine_members($name);
	}

	return \%groups;
}

=method normalize

Used internally to normalize group specifications.

See L</GROUP SPECIFICATION>.

=cut

sub normalize {
	my ($self, $spec) = @_;

	# if not a hashref, assume it's an (array of) item(s)
	$spec = {include => $spec}
		unless ref $spec eq 'HASH';

	while( my ($alias, $name) = each %spec_aliases ){
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

1;

=head1 DESCRIPTION

=head1 GROUP SPECIFICATION

A group specification can be in one of the following formats:

=begin :list

= I<scalar>
A single member;
This is converted to an array ref with one element.

= I<array ref>
An array of members.
This is converted into a hash ref with the C<items> key.

= I<hash ref>
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
an array ref with a single element.

=end :list

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
