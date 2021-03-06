#!/usr/bin/env perl
use strict;
use warnings;

use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Data::Dumper;
use threads;
use Thread::Queue;
use threads::shared;
use File::Slurp;

Log::Log4perl::init('log4perl.conf');
my $logger = get_logger('compare_platform');

my ($execution_id, $required_cpus) = @ARGV;

my $threads_number = 6;

my @benchmarks;

my $nasa_benchmark_class = 'B';
my $nasa_benchmarks_path = 'benchmarks';
my @nasa_included_benchmarks = ('cg');
push @benchmarks, map {"$nasa_benchmarks_path/$_.$nasa_benchmark_class.$required_cpus"} (@nasa_included_benchmarks);

my $new_benchmarks_path = 'new_benchmarks';
my @new_included_benchmarks = ('pairs', 'neighbour', 'circular');
#push @benchmarks, map {"$new_benchmarks_path/$_"} (@new_included_benchmarks);

my $collective_benchmarks_path = 'collective';
my @collective_included_benchmarks =  ('osu_allreduce', 'osu_alltoallv', 'osu_scatter', 'osu_allgather', 'osu_gather', 'osu_reduce_scatter', 'osu_allgatherv', 'osu_barrier', 'osu_reduce', 'osu_bcast', 'osu_alltoall');
#push @benchmarks, map {"$collective_benchmarks_path/$_"} (@collective_included_benchmarks);

my $mpi_benchmarks_path = 'mpi-benchmarks';
my @mpi_benchmarks_included_benchmarks = ('osu_bw');
#push @benchmarks, map {"$mpi_benchmarks_path/$_"} (@mpi_benchmarks_included_benchmarks);

my $base_path = "experiment/combinations/combinations-$execution_id";
my $platform_file = "$base_path/platform.xml";
my $permutations_file = "$base_path/permutations";
my $results_file = "$base_path/compare_platform-$execution_id.csv";
my $hosts_file = "$base_path/hosts";

$logger->info("running execution id $execution_id, $required_cpus required cpus, $threads_number threads");
$logger->info("running benchmarks: @benchmarks");

# Refuse to start if the directory or one of the files doesn't exist
$logger->logdie("experiment directory doesn't exist at $base_path") unless (-d $base_path);

# Refuse to start if the results file already exists
$logger->logdie("results file already exists at $results_file") if (-e $results_file);

my $results = [];
share($results);

my @permutation_lines = read_file($permutations_file, chomp => 1);
my $header = shift @permutation_lines; # remove header from file
my @permutations;

for my $permutation_line (@permutation_lines) {
	my @permutation_line_parts = split(' ', $permutation_line);
	push @permutations, $permutation_line_parts[0];
}

my @hosts = read_file($hosts_file, chomp => 1);

$logger->info("creating queue\n");
my $q = Thread::Queue->new();
$q->enqueue($_) for (0..$#permutations);
$q->end();

$logger->info("creating threads");
my @threads = map { threads->create(\&run_instance, $_) } (0..($threads_number - 1));

$logger->debug("waiting for threads to finish");
$_->join() for (@threads);

write_results();

sub run_instance {
	my $id = shift;

	my $logger = get_logger('compare_platform::run_instance');

	while (defined(my $instance = $q->dequeue_nb())) {
		my $instance_hosts_file = "/tmp/hosts-$instance-$id";
		write_host_file($permutations[$instance], $instance_hosts_file);

		my $results_instance = [];
		share($results_instance);

		$logger->info("thread $id runing $instance");

		for my $benchmark_number (0..$#benchmarks) {
			my $result = `./scripts/smpi/smpireplay.sh $required_cpus $platform_file $instance_hosts_file $benchmarks[$benchmark_number]`;

			unless ($result =~ /Simulation time (\d*\.\d*)/) {
				$logger->logdie("error while running smpireplay : ./scripts/smpi/smpireplay.sh $required_cpus $platform_file $instance_hosts_file $benchmarks[$benchmark_number]");
			}

			$results_instance->[$benchmark_number] = $1;
		}

		$results->[$instance] = $results_instance;
	}

	return;
}

sub write_host_file {
	my $permutation = shift;
	my $output_file = shift;

	my @cpus = split('-', $permutation);
	my @selected_hosts = map { $hosts[$_] } (@cpus);
	write_file($output_file, map { "$_\n" } (@selected_hosts));
}

sub get_log_file {
	return "log/compare_platform.log";
}

sub write_results {
	open(my $file, '>', $results_file);
	print $file "PERMUTATION " . join(' ' , @benchmarks) . "\n";

	for my $permutation_number (0..$#permutations) {
		my @results_temp = @{$results->[$permutation_number]}[0..$#benchmarks];
		my $position = $results->[$permutation_number]->[$#benchmarks + 1];
		print $file join(' ', $permutations[$permutation_number], @{$results->[$permutation_number]}) . "\n";
	}

	return;
}


