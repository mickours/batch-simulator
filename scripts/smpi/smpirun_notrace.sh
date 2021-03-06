#!/bin/sh
CPUS=$1
PLATFORMFILE=$2
HOSTFILE=$3
BENCHMARK=$4

# Generates a time independent trace for replaying the application

test -f $BENCHMARK-$CPUS.log && exit 0

smpirun -np $CPUS -platform $PLATFORMFILE -hostfile $HOSTFILE \
	--cfg=smpi/privatize_global_variables:yes \
	--cfg=smpi/running_power:23.492E9 \
	--cfg=smpi/display_timing:1 \
	$BENCHMARK | tee  $BENCHMARK-$CPUS.log 2>&1
