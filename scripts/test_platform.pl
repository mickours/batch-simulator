#!/usr/bin/env perl
use strict;
use warnings;

use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Time::HiRes qw(time);

use Platform;
use Data::Dumper;

Log::Log4perl::init('log4perl.conf');

my $logger = get_logger('test');

my @levels = (1, 2, 6, 96);
my @available_cpus = (0..($levels[$#levels] - 1));

my $removed_cpus_number = 0;
my $required_cpus = 8;

for my $i (0..($removed_cpus_number - 1)) {
	my $position = int(rand($levels[$#levels] - 1 - $i));
	splice(@available_cpus, $position, 1);
}

$logger->debug("available cpus: @available_cpus");

my $platform = Platform->new(\@levels, \@available_cpus, 1);
$platform->build_structure();
#print Dumper($platform->{root});
my @selected_cpus = $platform->choose_cpus($required_cpus);
$logger->info("cpus: @selected_cpus");

$platform->build_platform_xml();
$platform->save_platform_xml('test.xml');
Platform::save_hostfile(\@selected_cpus, 'test.hosts');

#for my $norm (1, 2, 3, 4, 5, 6) {
#	$platform = Platform->new(\@levels, \@available_cpus, $norm);
#	$platform->build_structure();
#	#print Dumper($platform->{root});
#	my @selected_cpus = $platform->choose_cpus($required_cpus);
#	$logger->info("norm: $norm, cpus: @selected_cpus");
#}
