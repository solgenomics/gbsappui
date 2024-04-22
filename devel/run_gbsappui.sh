#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
# run_filtering=$3

#functions:
#beagle function
echo "Test mail from postfix" | mail -s "Test Postfix" awl67@cornell.edu
beagle () {
    cd $projdir
    echo "Running beagle."
    echo "Project directory is $projdir ."
    if [ -d ${projdir}beagle ]; then
        echo "Already ran beagle"
    else
        mkdir ${projdir}beagle
        beagle_output=${projdir}beagle/beagle.out
        beagle_software=/beagle/beagle.*.jar
        export J2SDKDIR=/GBSapp/tools/jdk8u322-b06
        export J2REDIR=/GBSapp/tools/jdk8u322-b06
        export PATH=$PATH:/GBSapp/tools/jdk8u322-b06/bin:/GBSapp/tools/jdk8u322-b06/db/bin
        export JAVA_HOME=/GBSapp/tools/jdk8u322-b06
        export DERBY_HOME=/GBSapp/tools/jdk8u322-b06
        java -Xmx50g -jar ${beagle_software} gt=${gbs_output} out=${beagle_output}
        #check that beagle is done
        until [ -f $beagle_output.vcf.gz ]
        do
            sleep 10
        done
        echo "Beagle complete." >> ${projdir}beagle_log.out
        mv ${projdir}beagle_log.out ${projdir}beagle/
    fi
}

#filter function
# filter () {
#     cd /gbsappui/devel/
#     if [ $run_beagle = 1 ]; then
#         gzip -d $beagle_output.vcf.gz
#         perl ./filter_imputed_genotype.pl -i $beagle_output.vcf
#     else
#         gzip -d $gbs_output
#         perl ./filter_imputed_genotype.pl -i $gbs_output
#     fi
# }

bash /GBSapp/GBSapp $projdir

#check for analysis completion
until [ -f ${projdir}Analysis_Complete ]
do
    sleep 10
done

#edit gbs result permissions
chmod -R 770 ${projdir}

#move gbs slurm files to output file once gbs is done running
mv ${projdir}slurm*.out ${projdir}gbs_slurm_log/

#run beagle/filtering script
#add the following if you add filtering part:
# if [ $run_beagle = 1 ] || [ $run_filtering = 1 ]; then
    # sbatch /gbsappui/devel/run_beagle_filtering.sh $projdir $run_beagle $run_filtering
# fi

#run beagle
if [ $run_beagle = 1 ]; then
    #identify gbs output to use for beagle
    gbs_output=$(ls ${projdir}snpcall/*x.vcf*)
    beagle &>> ${projdir}beagle_log.out
fi

#run filtering
# if [ $run_filtering = 1 ]; then
#     filter &>> ${projdir}filter_log.out
# fi
