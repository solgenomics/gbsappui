#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
email_address=$3
gbsappui_domain_name=$4
# run_filtering=$5

#run GBSapp
chmod -R 770 ${projdir}
cd ${projdir}gbsappui_slurm_log
sbatch /gbsappui/devel/run_gbsappui.sh $projdir $run_beagle $email_address $gbsappui_domain_name
