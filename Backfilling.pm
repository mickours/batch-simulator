package Backfilling;
use parent 'Schedule';
use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Trace;
use Job;
use Processor;
use ExecutionProfile;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->{execution_profile} = new ExecutionProfile($self->{processors}, $self->{contiguous});
	$self->{contiguous_jobs_number} = 0;

	return $self;
}

sub assign_job {
	my ($self, $job) = @_;
	my $requested_cpus = $job->requested_cpus();

	#get the first valid profile_id for our job
	$self->{execution_profile}->set_current_time($job->submit_time());
	my ($chosen_profile, $chosen_processors, $contiguous) = $self->{execution_profile}->find_first_profile_for($job);
	my $starting_time = $self->{execution_profile}->starting_time($chosen_profile);

	$self->{contiguous_jobs_number}++ if ($contiguous);

	#assign job
	$job->assign_to($starting_time, $chosen_processors);

	#update profiles
	$self->{execution_profile}->add_job_at($job);
}

sub contiguous_jobs_number {
	my $self = @_;
	return $self->{contiguous_jobs_number};
}

1;
