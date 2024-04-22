#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
# run_filtering=$3
gbs_output=$(ls ${projdir}snpcall/*x.vcf*)

#beagle function
beagle () {
    cd $projdir
    echo "running beagle"
    echo "gbs output is ${gbs_output}"
    echo "gbs output without brakcets is $gbs_output"
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
        echo "Beagle complete"
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

#run beagle
if [ $run_beagle = 1 ]; then
    beagle &>> ${projdir}beagle_log.out
fi

#run filtering
# if [ $run_filtering = 1 ]; then
#     filter &>> ${projdir}filter_log.out
# fi
