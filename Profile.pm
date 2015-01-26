package Profile;

use Carp;

use ProcessorRangeOld;

use strict;
use warnings;
use overload
	'""' => \&stringification;

use List::Util qw(min);

#a profile objects encodes a set of free processors at a given time

sub initial {
	my $class = shift;
	my $self = {};
	$self->{starting_time} = shift;
	$self->{processors} = new ProcessorRangeOld(@_);
	$self->{duration} = undef;
	bless $self, $class;
	return $self;
}

sub new {
	my $class = shift;
	my $self = {};
	$self->{starting_time} = shift;
	my $ids = shift;
	if (ref $ids eq "ProcessorRangeOld") {
		$self->{processors} = $ids;
	} else {
		$self->{processors} = new ProcessorRangeOld($ids);
	}
	$self->{duration} = shift;

	bless $self, $class;
	return $self;
}

sub processor_range {
	my $self = shift;
	return $self->{processors};
}

sub stringification {
	my $self = shift;
	return "[$self->{starting_time} ; ($self->{processors}) ; $self->{duration}]" if defined $self->{duration};
	return "[$self->{starting_time} ; ($self->{processors}) ]";
}

sub processors_ids {
	my $self = shift;
	return $self->{processors};
}

sub duration {
	my $self = shift;
	$self->{duration} = shift if @_;
	return $self->{duration};
}

#returns two or one profile if it is split or not by job insertion
sub add_job {
	my ($self, $job, $current_time) = @_;

	die unless defined $current_time;
	die if $self->{starting_time} >= $job->ending_time_estimation($current_time);

	if (defined $self->ending_time() and $self->ending_time() <= $job->starting_time()) {
		print "job $job\n";
		print "self $self\n";
		print $job->starting_time() . "\n";
		confess;
	}

	return $self->split($job, $current_time);
}

#free some processors by canceling a job
sub remove_job {
	my $self = shift;
	my $job = shift;
	$self->{processors}->add($job->assigned_processors_ids());
	return $self;
}

#TODO : not very pretty ?
#TODO : documentation
sub split {
	my $self = shift;
	my $job = shift;
	my $current_time = shift;

	my @profiles;
	my $middle_start = $self->{starting_time};
	my $middle_end;

	if (defined $self->{duration}) {
		$middle_end = min($self->ending_time(), $job->ending_time_estimation($current_time));
	} else {
		$middle_end = $job->ending_time_estimation($current_time);
	}

	my $middle_duration = $middle_end - $middle_start if defined $middle_end;
	my $middle_profile = new Profile($middle_start, new ProcessorRangeOld($self->{processors}), $middle_duration);
	$middle_profile->remove_used_processors($job);
	push @profiles, $middle_profile unless $middle_profile->is_fully_loaded();

	if ((not defined $self->ending_time()) or ($job->ending_time_estimation($current_time) < $self->ending_time())) {
		my $end_duration;
		if (defined $self->{duration}) {
			$end_duration = $self->ending_time() - $job->ending_time_estimation($current_time);
		}
		my $end_profile = new Profile($job->ending_time_estimation($current_time), new ProcessorRangeOld($self->{processors}), $end_duration);
		push @profiles, $end_profile;
	}
	return @profiles;
}

sub is_fully_loaded {
	my $self = shift;
	return $self->{processors}->is_empty();
}

sub remove_used_processors {
	my $self = shift;
	my $job = shift;
	$self->{processors}->remove($job->assigned_processors_ids());
}

sub starting_time {
	my $self = shift;
	$self->{starting_time} = shift if @_;
	return $self->{starting_time};
}

sub ending_time {
	my $self = shift;
	return unless defined $self->{duration};
	return $self->{starting_time} + $self->{duration};
}

1;
