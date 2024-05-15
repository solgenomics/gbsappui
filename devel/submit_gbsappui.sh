#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
# run_filtering=$3

#run GBSapp
chmod -R 777 ${projdir}
cd ${projdir}gbsappui_slurm_log
sbatch /gbsappui/devel/run_gbsappui.sh $projdir $run_beagle
