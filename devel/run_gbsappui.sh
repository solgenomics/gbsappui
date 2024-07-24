#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
email_address=$3
# run_filtering=$4

#functions:
initial_email () {
    #formatting email
    body=$1
    #send email
    /gbsappui/devel/mail.sh "$email_address" "GBSapp Analysis Begun" "$body" "" "";
}

error_email () {
    #formatting email
    body=$1
    #zip logfile for sending
    cp ${projdir}log.out ${projdir}log2.out
    gzip ${projdir}log2.out
    mv ${projdir}log2.out.gz ${projdir}log.out.gz

    #send email
    /gbsappui/devel/mail.sh "$email_address" "GBSapp Error" "$body" "${projdir}log.out.gz" "$gbs_slurm_log";
}

results_email () {
    #zip file and move to results folder
    nopath_projdir=$(echo $projdir | awk '{n=split($0,a,"/");print a[3]}')
    cd ${projdir}
    tar -zcvf /gbsappui/root/results/analysis_results.tar.gz *
    chmod 777 /gbsappui/root/results/analysis_results.tar.gz
    #email results link
    #format email
    body="The results for your GBSapp analysis can be found at the following link: http://localhost:8090/results/"
    #send email
    /gbsappui/devel/mail.sh "$email_address" "GBSapp Results" "$body" "" "";
}

#beagle function
beagle () {
    cd $projdir
    echo "Running beagle."
    echo "Project directory is $projdir ."
    # if [ -d ${projdir}beagle ]; then
    #     echo "Already ran beagle"
    # else
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
    # fi;
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

#send initial email to test if the email is working
initial_body="Your GBS analysis has begun! You will receive the results at this address when it completes. "
initial_email "$initial_body"
#working I think
chmod -R 770 ${projdir}
cd ${projdir}
bash /GBSapp/GBSapp $projdir
sleep 10
#get job numbers
jobnum_gbsappui=$(ls ${projdir}gbsappui_slurm_log/slurm* | awk '{n=split($0,a,"-");print a[2]}' | awk 'BEGIN { ORS=" "};{n=split($0,a,".");print a[1]}' )
jobnum_gbsapp=$(ls "${projdir}slurm"* | awk '{n=split($0,a,"-");print a[2]}' | awk 'BEGIN { ORS=" "};{n=split($0,a,".");print a[1]}' )
#move slurm log to gbs_slurm_log
gbs_slurm_log=$(ls ${projdir}slurm*.out )
##Wait until the slurm job is done
until [ $(squeue -j $jobnum_gbsapp -h --noheader | wc -l) -eq 0 ]; do
    sleep 60
    #get the time the slurm job has been running
    if [ $(squeue -j $jobnum_gbsapp -h --noheader | wc -l) -eq 0 ]; then
        :
    elif [ $(squeue -j $jobnum_gbsapp -h --noheader | awk '{n=split($0,a," ");print a[6]}' | awk '{n=split($0,a,":");print a[1]}' | awk '{n=split($0,a,":");print a[1]}' ) -gt 95 ]; then
        scancel $jobnum_gbsappui
        scancel $jobnum_gbsapp
        last_log=$(tail -n 5 $gbs_slurm_log)
        body="GBS Analysis timed out after 96 hours. Final log lines include:

        $last_log

        Full log files attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
        error_email "$body"
    fi
done

#Check if analysis completed successfully and get information for email
#get end of log file for error handling
last_log=$(tail -n 5 $gbs_slurm_log)
if [ -f ${projdir}Analysis_Complete ]; then
    #edit gbs result permissions
    chmod -R 770 ${projdir}
    #check for vcf result files
    if [ -f ${projdir}snpcall/*x.vcf.gz ]; then
        #Either run beagle imputation
        if [ $run_beagle = 1 ]; then
            gbs_output=$(ls ${projdir}snpcall/*x.vcf.gz )
            beagle &>> ${projdir}beagle_log.out
            #once beagle analysis is complete email results
            results_email
        #else email results with no beagle imputation
        else
            results_email
        fi
    #if no vcf file
    else
        body="GBS Analysis completed but failed to produce a results file. Final log lines include:

        $last_log

        Full log files also attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
        error_email "$body"
    fi
#if no Analysis_Complete
else
    body="GBS Analysis did not complete successfully. Final log lines include:

    $last_log

    Full log files also attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
    error_email "$body"
fi
