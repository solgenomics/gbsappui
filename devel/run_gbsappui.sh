#!/bin/bash

#parameters:
projdir=$1
run_beagle=$2
email_address=$3
gbsappui_domain_name=$4
run_gbsapp=$5
analysis_name="$6"
# run_filtering=$7

#Fill out analysis information into analysis_info.txt
cd ${projdir}
sed -i -e '$a\' analysis_info.txt
echo "Analysis Name: ${analysis_name}" >> analysis_info.txt

echo "#####SNP Calling/Filtering" >> analysis_info.txt
if [[ "$run_gbsapp" == 1 ]]; then
    echo "SNP Calling: yes" >> analysis_info.txt
    echo "SNP Filtering: yes" >> analysis_info.txt
    echo "SNP Calling/Filtering Input sample files: See samples_list_node_1.txt" >> analysis_info.txt
    echo "SNP Calling/Filtering Input reference genome file:"  >> analysis_info.txt
    refgenome=$(ls ${projdir}refgenomes)
    echo "SNP Calling/Filtering Input reference genome file(s): ${refgenome}" >>analysis_info.txt
    echo "Minor Allele Frequency Threshold: 0.02" >>analysis_info.txt
    echo "SNP Calling/Filtering Log File: gbsapp_log.out" >>analysis_info.txt
    echo "SNP Calling Output File: " >>analysis_info.txt
    echo "SNP Filtering Output File: " >>analysis_info.txt
else
    echo "SNP Calling: no" >> analysis_info.txt
    echo "SNP Filtering: no" >> analysis_info.txt
fi

echo "#####Imputation" >> analysis_info.txt
if [[ "$run_beagle" == 1 ]]; then
    echo "Imputation: yes" >> analysis_info.txt
    echo "Imputation Log File: beagle_log.out" >> analysis_info.txt
    echo "Imputation Output File: /beagle/beagle.out.vcf.gz" >> analysis_info.txt
else
    echo "Imputation: no" >> analysis_info.txt
fi

cd ${projdir}gbsappui_slurm_log

#functions:
initial_email () {
    #formatting email
    body=$1
    #send email
    /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Analysis Begun" "$body" "" ""
}

error_email_gbsapp () {
    #formatting email
    body=$1
    #zip logfile for sending
    cp ${projdir}log.out ${projdir}log2.out
    gzip ${projdir}log2.out
    mv ${projdir}log2.out.gz ${projdir}log.out.gz

    #send email
    /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Error" "$body" "${projdir}log.out.gz" "$gbs_slurm_log"
}

error_email_beagle () {
    #formatting email
    body=$1
    #send email including log file only if it exists
    if [ -f ${projdir}beagle/beagle_log.out ]; then
        /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Error" "$body" "$beagle_log"
    else
        /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Error" "$body"
    fi
}

results_email () {
    #zip file and move to results folder
    nopath_projdir_username=$(echo $projdir | awk '{n=split($0,a,"/");print a[3]}')
    nopath_projdir_analysis=$(echo $projdir | awk '{n=split($0,a,"/");print a[4]}')
    cd ${projdir}
    #make project and user directories if they don't exist
    if [ -d /gbsappui/root/results/$nopath_projdir_username/ ]; then
        mkdir /gbsappui/root/results/$nopath_projdir_username/$nopath_projdir_analysis/
    else
        mkdir /gbsappui/root/results/$nopath_projdir_username/
        mkdir /gbsappui/root/results/$nopath_projdir_username/$nopath_projdir_analysis/
    fi
    rm -rf /results/$nopath_projdir_username/$nopath_projdir_analysis/samples/*fastq*
    rm -rf /results/$nopath_projdir_username/$nopath_projdir_analysis/samples/*fasta*
    tar -zcvf /gbsappui/root/results/$nopath_projdir_username/$nopath_projdir_analysis/analysis_results.tar.gz *
    chmod 777 /gbsappui/root/results/$nopath_projdir_username/$nopath_projdir_analysis/analysis_results.tar.gz
    #email results link
    #format email to handle spaces
    url_analysis_name=${analysis_name// /"%20"}

    if [[ ($run_gbsapp -eq 1) && ($run_beagle -eq 1)]]; then
        #If there was a beagle error but gbsapp completed successfully then still email the results along with the beagle error
        if [ $beagle_error -eq 1 ]; then
            body="Calling and filtering for analysis ${analysis_name} completed successfully but imputation did not. Calling and filtering results can be found at the following link: ${gbsappui_domain_name}/results/?&username=${nopath_projdir_username}&projdir=${nopath_projdir_analysis}&analysis_name=${url_analysis_name} Error message(s) include:
            $beagle_error_lines
            $beagle_exception_lines
            $beagle_illegal_lines
            $beagle_terminating_lines The imputation log file (if available) is attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            if [ -f ${projdir}beagle/beagle_log.out ]; then
                /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Results/Error" "$body" "$beagle_log"
            else
                /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Results/Error" "$body"
            fi
        else
            #if imputation and gbsapp were conducted then include info on what input file imputation was conducted on
            body="The results for your BreedBase Call analysis ${analysis_name} can be found at the following link: ${gbsappui_domain_name}/results/?&username=${nopath_projdir_username}&projdir=${nopath_projdir_analysis}&analysis_name=${url_analysis_name} Imputation was conducted after the ${beagle_input} step."
        fi
    else
        body="The results for your BreedBase Call analysis ${analysis_name} can be found at the following link: ${gbsappui_domain_name}/results/?&username=${nopath_projdir_username}&projdir=${nopath_projdir_analysis}&analysis_name=${url_analysis_name}"
    fi
    #send email
    /gbsappui/devel/mail.sh "$email_address" "BreedBase Call Results" "$body" "" "";
}

#beagle function
beagle () {
    cd $projdir
    echo "Running beagle."
    echo "Project directory is $projdir ."
    beagle_error=0
    # if [ -d ${projdir}beagle ]; then
    #     echo "Already ran beagle"
    # else
        beagle_output=${projdir}beagle/beagle.out
        beagle_software=/beagle/beagle.*.jar
        export J2SDKDIR=/GBSapp/tools/jdk8u322-b06
        export J2REDIR=/GBSapp/tools/jdk8u322-b06
        export PATH=$PATH:/GBSapp/tools/jdk8u322-b06/bin:/GBSapp/tools/jdk8u322-b06/db/bin
        export JAVA_HOME=/GBSapp/tools/jdk8u322-b06
        export DERBY_HOME=/GBSapp/tools/jdk8u322-b06
        java -Xmx50g -jar ${beagle_software} gt=${gbs_output} out=${beagle_output}
        #check that beagle is done
        until [ -f $beagle_output.vcf.gz ]; do
            sleep 30
            #check for errors
            beagle_log=$(ls ${projdir}beagle/beagle_log.out )
            beagle_error_lines=$(grep -hr "ERROR" $beagle_log)
            beagle_exception_lines=$(grep -hr "Exception" $beagle_log)
            beagle_illegal_lines=$(grep -hr "Illegal" $beagle_log)
            beagle_terminating_lines=$(grep -hr "Terminating" $beagle_log)
            #if there's an error in the log file set error variable
            if [[ ($(echo $beagle_error_lines | wc -w) -gt 0) || ($(echo $beagle_exception_lines | wc -w) -gt 0) || ($(echo $beagle_illegal_lines | wc -w) -gt 0) || ($(echo $beagle_terminating_lines | wc -w) -gt 0) ]]; then
                beagle_error=1
                echo "beagle error"
                exit 0
            fi
            if [ $(squeue -j $jobnum_gbsappui -h --noheader | awk '{n=split($0,a," ");print a[6]}' | awk '{n=split($0,a,":");print a[1]}' | awk '{n=split($0,a,":");print a[1]}' ) -gt 95 ]; then
                scancel $jobnum_gbsappui
                gbsappui_slurm_log=$(ls ${projdir}gbsappui_slurm_log/slurm*.out )
                last_log=$(tail -n 5 $gbsappui_slurm_log)
                body="Imputation analysis ${analysis_name} timed out after 96 hours. Final log lines include:

                $last_log

                Full log files attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
                error_email_beagle "$body"
                beagle_error=1
                exit 0
            fi
        done
        #remove duplicate auto-generated log file
        rm ${projdir}beagle/beagle.out.log
        #make analysis finished file if it completed successfully
        if [ $beagle_error -eq 0 ]; then
            touch ${projdir}beagle/beagle_complete
        fi
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

gbsapp () {
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
            body="GBS Analysis ${analysis_name} timed out after 96 hours. Final log lines include:

            $last_log

            Full log files attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            error_email_gbsapp "$body"
            exit 0
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
            #if imputation isn't selected
            if [ $run_beagle -eq 0 ]; then
                results_email
            fi
        #if no vcf file
        else
            body="Calling and Filtering for analysis ${analysis_name} completed but failed to produce results files. Final log lines include:

            $last_log

            Full log files also attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            error_email_gbsapp "$body"
            exit 0
        fi
    #if no Analysis_Complete result
    else
        if [ -f ${projdir}snpcall/*x.vcf.gz ]; then
            touch ${projdir}Analysis_Complete
            #if imputation isn't selected
            if [ $run_beagle -eq 0 ]; then
                results_email
            fi
        #if no vcf file
        else
            body="Calling and Filtering for analysis ${analysis_name} completed but failed to produce results files. Final log lines include:

            $last_log

            Full log files also attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            error_email_gbsapp "$body"
            exit 0
        fi
    fi
}

#send initial email to test if the email is working
initial_body="Your BreedBase Call analysis ${analysis_name} has begun! You will receive the results at this address when it completes. "
initial_email "$initial_body"
chmod -R 770 ${projdir}
cd ${projdir}

#Run gbsapp if selected
if [ $run_gbsapp -eq 1 ]; then
    gbsapp
fi

#Run beagle imputation if selected
if [ $run_beagle -eq 1 ]; then
    #If only doing imputation
    if [ $run_gbsapp -eq 0 ]; then
        if [ -f ${projdir}*vcf* ]; then
            gbs_output=$(ls ${projdir}*vcf* )
        else
            body="Imputation for analysis ${analysis_name} did not complete successfully. The input vcf file to impute could not be found. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            error_email_beagle "$body"
            exit 0
        fi
    fi
    #If doing imputation after gbsapp analysis
    if [ $run_gbsapp -eq 1 ]; then
        #if there's a snpfilter file run it on that
        if [ -f ${projdir}snpfilter/*x_diversity*/*.vcf.gz ]; then
            gbs_output=$(ls ${projdir}snpfilter/*x_diversity*/*.vcf.gz)
            beagle_input="SNP filtering"
        #otherwise run it on the snpcall file
        elif [ -f ${projdir}snpcall/*x.vcf.gz ]; then
            gbs_output=$(ls ${projdir}snpcall/*x.vcf.gz)
            beagle_input="SNP calling"
        else
            body="Calling and filtering for analysis ${analysis_name} did not complete successfully. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            error_email_beagle "$body"
            exit 0
        fi
    fi
    #run beagle
    mkdir ${projdir}beagle
    beagle &>> ${projdir}beagle/beagle_log.out
    #check for imputation error
    if [ $beagle_error -eq 1 ]; then
        #if calling and filtering was run successfully
        if [ $run_gbsapp -eq 1 ]; then
            results_email
            exit 0
        #else just send error message
            body="Imputation for analysis ${analysis_name} did not complete successfully. Error message(s) include:
            $beagle_error_lines
            $beagle_exception_lines
            $beagle_illegal_lines
            $beagle_terminating_lines Full log file also attached. Please email Amber Lockrow to resolve this error at awl67@cornell.edu"
            error_email_beagle "$body"
            exit 0
        fi
    #once beagle analysis is complete if there is no error email results
    elif [ $beagle_error -eq 0 ]; then
            results_email
    fi
fi
