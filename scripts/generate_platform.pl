#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);

use Platform;

Log::Log4perl::init('log4perl.conf');
my $logger = get_logger('test');

my ($levels) = @ARGV;

my @level_parts = split('-', $levels);
my @available_cpus = (0..($level_parts[-1] - 1));

# Put everything in the log file
$logger->info("platform: @level_parts");

my $platform = Platform->new(\@level_parts, \@available_cpus, 1);
$platform->build_structure();
$platform->build_platform_xml();
$platform->save_platform_xml('platform.xml');

sub get_log_file {
	return "log/generate_platform.log";
}


