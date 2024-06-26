#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
email_address=$3
# run_filtering=$4

#run GBSapp
chmod -R 777 ${projdir}
cd ${projdir}gbsappui_slurm_log
sbatch /gbsappui/devel/run_gbsappui.sh $projdir $run_beagle $email_address
