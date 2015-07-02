#!/usr/bin/env perl
use strict;
use warnings;

use Algorithm::Permute;
use Data::Dumper;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use List::Util qw(min max reduce);

use Platform;

Log::Log4perl::init('log4perl.conf');
my $logger = get_logger('test');

my @levels = (1,3,6,12);
my @available_cpus = (0..($levels[$#levels] - 1));
#my @available_cpus = (0, 1, 2, 4, 5);
my $required_cpus = 8;
my $combinations_file_name = "permutations";
my $cluster_size = $levels[-1]/$levels[-2];

# Put everything in the log file
$logger->info("platform: @levels");
$logger->info("available cpus: @available_cpus");
$logger->info("required cpus: $required_cpus");

my @combinations = generate_unique_combinations(2, 0);
print Dumper(@combinations);
die;
save_combinations();

sub generate_unique_combinations {
	my $required_cpus = shift;
	my $level = shift;

	return "$required_cpus" if ($level == $#levels - 1);

	my @next_combinations = next_combinations($required_cpus, $level + 1, 0, $required_cpus);
	my @combinations;

	for my $next_combination (@next_combinations) {
		my @merging_combinations;
		my @combination_parts = split('-', $next_combination);
		for my $node_number (0..$#combination_parts) {
			my @node_combinations = generate_unique_combinations($combination_parts[$node_number], $level + 1);
			@merging_combinations = merge_combinations(\@merging_combinations, \@node_combinations);
		}
		push @combinations, @merging_combinations;
	}
	return @combinations;
}

sub merge_combinations {
	my $combinations = shift;
	my $node_combinations = shift;

	my @merged_combinations;

	# On the first call $combinations will be empty
	return @$node_combinations unless (@{$combinations});

	for my $combination (@$combinations) {
		for my $node_combination (@$node_combinations) {
			push @merged_combinations, join('-', $combination, $node_combination);
		}
	}

	return @merged_combinations;
}

sub next_combinations {
	my $required_cpus = shift;
	my $level = shift;
	my $node_number = shift;
	my $maximum_cpus = shift;

	return if ($node_number >= $levels[$level]);

	my @combinations;
	my $total_level_size = $levels[-1]/$levels[$level];

	for (my $cpus_number = min($total_level_size, $maximum_cpus); $cpus_number >= 1; $cpus_number--) {
		if ($required_cpus - $cpus_number) {
			my @next_combinations = next_combinations($required_cpus - $cpus_number, $level, $node_number + 1, $cpus_number);
			push @combinations, join('-', $cpus_number, $_) for (@next_combinations);

		} else {
			push @combinations, "$cpus_number";
		}
	}
	return @combinations;
}

sub save_combinations {
	open(my $file, '>', $combinations_file_name);

	for my $combination (@combinations) {
		my @combination_parts = split('-', $combination);
		my @selected_cpus;
		for my $node_number (0..$#combination_parts) {
			my @cluster_cpus = map {$node_number * $cluster_size + $_} (0..($combination_parts[$node_number] - 1));
			push @selected_cpus, @cluster_cpus;
		}

		print $file join('-', @selected_cpus) . "\n";
	}

	return;
}

sub get_log_file {
	return "log/generate_combinations.log";
}


