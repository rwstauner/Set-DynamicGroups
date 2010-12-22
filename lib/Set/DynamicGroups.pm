package Set::DynamicGroups;
# ABSTRACT: Manage groups of items dynamically

=head1 SYNOPSIS

	use Set::DynamicGroups;

	my $set = Set::DynamicGroups->new();
	$set->append(groupname => 'member1');

=cut

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {
		groups => {},
	};
	bless $self, $class;
}

=method append

	$set->append(groupname => \@members);

Append members to the specified group.

=cut

sub append {
	my ($self) = shift;
	my %groups = ref $_[0] ? %{$_[0]} : @_;
	while( my ($group, $fields) = each %groups ){
		$fields = [$fields]
			unless ref $fields;
		push(@{ $self->{groups}->{$group} ||= [] }, @$fields);
	}
	return $self;
}

1;
