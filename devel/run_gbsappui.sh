#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
# run_filtering=$3

#run GBSapp
cd $projdir
bash /GBSapp/GBSapp $projdir

#check for analysis completion
until [ -f ./Analysis_Complete ]
do
    sleep 10
done

#remove gbs slurm files
rm ${projdir}slurm*.out

#edit gbs result permissions
chmod -R 770 ${projdir}

#run beagle/filtering script
#add the following when you add filtering part:
# if [ $run_beagle = 1 ] || [ $run_filtering = 1 ]; then
    # sbatch /gbsappui/devel/run_beagle_filtering.sh $projdir $run_beagle $run_filtering
# fi
if [ $run_beagle = 1 ]; then
    sbatch /gbsappui/devel/run_beagle_filtering.sh $projdir $run_beagle
fi
