package ProcessorRange;

use strict;
use warnings;
use overload '""' => \&stringification;

sub new {
	my $class = shift;
	my $self = {};
	$self->{ranges} = [];
	my $processor_ids = shift;
	die 'not enough processors' unless @{$processor_ids};
	my @processor_ids = sort {$a <=> $b} @{$processor_ids};
	my $previous_id;
	for my $id (@processor_ids) {
		if ((not defined $previous_id) or ($previous_id != $id -1)) {
			push @{$self->{ranges}}, $previous_id if defined $previous_id;
			push @{$self->{ranges}}, $id;
		}
		$previous_id = $id;
	}
	push @{$self->{ranges}}, $previous_id;
	bless $self, $class;
	return $self;
}


sub intersection {
	# ranges[0] is $self and ranges[1] is other
	my @ranges = @_;

	my $inside_segments = 0;
	my $starting_point;
	my @result;
	
	my @indices = (0, 0);
	while (($indices[0] <= $#{$ranges[0]->{ranges}}) and ($indices[1] <= $#{$ranges[1]->{ranges}})) {
		# find next event
		my $advancing_range;
		my $event_type;

		if ($ranges[0]->{ranges}->[$indices[0]] <= $ranges[1]->{ranges}->[$indices[1]]) {
			$advancing_range = 0;
		} else {
			$advancing_range = 1;
		}

		$event_type = $indices[$advancing_range] % 2;
		if ($event_type == 0) {
			# start
			if ($inside_segments == 1) {
				$starting_point = $ranges[$advancing_range]->{ranges}->[$indices[$advancing_range]];
			}
			$inside_segments++;
		} else {
			# end of segment
			if ($inside_segments == 2) {
				push @result, $starting_point;
				push @result, $ranges[$advancing_range]->{ranges}->[$indices[$advancing_range]];
			}
			$inside_segments--;
		}
		$indices[$advancing_range]++;
	}

	$ranges[0]->{ranges} = [@result];
}

sub processors_ids {
	my $self = shift;
	my @ids;
	for my $i (0..(@{$self->{ranges}}-2)/2) {
		my $start = $self->{ranges}->[$i*2];
		my $end = $self->{ranges}->[$i*2+1];
		for my $j ($start..$end) {
			push @ids, $j;
		}
	}
	return @ids;
}

sub stringification {
	my $self = shift;
	my @strings;
	for my $i (0..((@{$self->{ranges}}-2)/2)) {
		my $start = $self->{ranges}->[$i*2];
		my $end = $self->{ranges}->[$i*2+1];
		push @strings, "[$start-$end]";
	}
	return join(' ', @strings);
}

1;
