package gbsappui::Controller::Gbsappui;
use Moose;
use Catalyst qw/Session Session::Store::File Session::State::Cookie/;
use Catalyst::Request;
use Catalyst::Request::Upload;
use Data::Dumper;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove rcopy_glob);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw/ :seekable /;
#use File::Find;
use JSON;
# use Time::Piece;
# use Time::Seconds;


BEGIN {extends 'Catalyst::Controller'};

sub get_token:Path('/get_token') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{template}="get_token.mas";
}

sub choose_pipeline:Path('/choose_pipeline') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    my $username=$c->req->param('username');
    my $sgn_token=$c->req->param('sgn_token');
    my $contact_email = $c->config->{contact_email};
    my $contact_name = $c->config->{contact_name};
    my $refs_json = $c->config->{refgenomes_json};
    my $raw_file_list = `ls -R /scp_uploads/$username`;
    my @beagle_error;
    my @gbs_error;
    my $epoch_timestamp;
    my $fh;
    my $timestamp;
    my @beagle_files;

    #retrieving list of scp files available for username
    my @file_list = split("\n", $raw_file_list);
    shift @file_list;
    my %files_of;
    $files_of{ $username } = \@file_list;
    my $file_list_json = encode_json \%files_of;

    #get list of analysis folders
    my $raw_analysis_folders = `ls /results/$username`;
    my @analysis_folders = split("\n", $raw_analysis_folders);
    #remove any starting or trailing white spaces
    foreach my $folder (@analysis_folders) {
        $folder =~ s/^\s+|\s+$//g;
    }

    #Make a hash and encode it into json format for analysis folders
    my %analyses_folders_of;
    $analyses_folders_of{ $username } = \@analysis_folders;
    my $analysis_folders_json = encode_json \%analyses_folders_of;

    #for each analysis
    #grab analysis name and analysis type from text file
    my @analysis_name_array;
    my @snp_calling_array;
    my @imputation_array;
    my @analysis_type_array;
    foreach my $folder (@analysis_folders) {
        my $analysis_name_string;
        my $snp_calling_string;
        my $imputation_string;
        my @text_file_exists = glob("/results/$username/$folder/analysis_info*.txt");
        if (@text_file_exists) {
            my $file_path = "/results/$username/$folder/analysis_info.txt";
            my $info_file;
            open $info_file, '<', $file_path or die "Could not open file '$info_file'";
            while (my $line = <$info_file>) {
                chomp $line;
                if ($line =~ /^Analysis Name:/) {
                    $analysis_name_string = $line;
                    $analysis_name_string =~ s/Analysis Name: //;
                    chomp $analysis_name_string;
                    push(@analysis_name_array, $analysis_name_string);
                }
                if ($line =~ /^SNP Calling:/) {
                    $snp_calling_string = $line;
                    $snp_calling_string =~ s/SNP Calling: //;
                    chomp $snp_calling_string;
                    push(@snp_calling_array, $snp_calling_string);
                }
                if ($line =~ /^Imputation:/) {
                    $imputation_string = $line;
                    $imputation_string =~ s/Imputation: //;
                    chomp $imputation_string;
                    push(@imputation_array, $imputation_string);
                }
            }
        } else { #if there's no analysis info text file
            push(@analysis_name_array, "Analysis name missing");
            push(@snp_calling_array, "SNP calling info missing");
            push(@imputation_array, "Imputation info missing");
        }
    }
    my $snp_calling_array = @snp_calling_array;
    for (my $i = 0; $i < $snp_calling_array; $i++) {
        if ($snp_calling_array[$i] eq "yes" && $imputation_array[$i] eq "yes") {
            $analysis_type_array[$i] = "Calling/Filtering/Imputation";
        }
        elsif ($snp_calling_array[$i] eq "no" && $imputation_array[$i] eq "yes") {
            $analysis_type_array[$i] = "Imputation";
        }
        elsif ($snp_calling_array[$i] eq "yes" && $imputation_array[$i] eq "no") {
            $analysis_type_array[$i] = "Calling/Filtering";
        }
        else {
            $analysis_type_array[$i] = "N/A";
        }
    }
    #Make a hash and encode it into json format for analysis names
    my %analyses_names_of;
    $analyses_names_of{ $username } = \@analysis_name_array;
    my $analysis_list_json = encode_json \%analyses_names_of;

    #Make a hash and encode it into json format for analysis types
    my %analyses_types_of;
    $analyses_types_of{ $username } = \@analysis_type_array;
    my $analysis_types_json = encode_json \%analyses_types_of;

    #Get start times for analyses
    my @start_times_array;
    my $analysis_folders = @analysis_folders;
    for (my $i = 0; $i < $analysis_folders; $i++) {
        my $folder = $analysis_folders[$i];
        if ($snp_calling_array[$i] eq "yes") {
            $fh="/results/$username/$folder/GBSapp_run_node_1.sh";
            $epoch_timestamp=(stat($fh))[9];
            if ($epoch_timestamp) {
                $timestamp=scalar localtime($epoch_timestamp);
            }
            else {
                $timestamp="N/A";
            }
        }
        else {
            $fh="/results/$username/$folder/beagle/beagle_log.out";
            $epoch_timestamp=(stat($fh))[9];
            if ($epoch_timestamp) {
                $timestamp=scalar localtime($epoch_timestamp);
            }
            else {
                $timestamp="N/A";
            }
        }
        push @start_times_array, $timestamp;
    }
    #format start times
    my %start_times_hash;
    $start_times_hash{ $username } = \@start_times_array;
    my $start_times_json= encode_json \%start_times_hash;

    #Get completion times for analyses
    my @status_array;
    my @finish_times_array;
    @status_array[0] = 0;


    #calculate analysis status and finish times
    for (my $i = 0; $i < $analysis_folders; $i++) {
        @status_array[$i] = "";
        my $folder = @analysis_folders[$i];
        my $path = "/results/$username/$folder";
        my $ui_log="$path/gbsappui_slurm_log";
        my @glob_slurm=glob("$ui_log/slurm*");
        my $slurm_command = `squeue -j --noheader`;
        $slurm_command = "$slurm_command";
        my @slurm_command_split = split /\s+/, $slurm_command;
        my $slurm_command_split_length = scalar @slurm_command_split;
        my $jobnum;
        if (@glob_slurm) {
            my $slurm_filename=`cd $ui_log; ls slurm*`;
            my @filename_array = split /[.-]/, $slurm_filename;
            $jobnum = @filename_array[1];
            #remove any starting or trailing white spaces
            $jobnum =~ s/^\s+|\s+$//g;
            my $analysis_name_temp = @analysis_name_array[$i];
        }
        if ($jobnum) { #Check if job is running
            my @jobnums_running;
            my $jobnums_running_length = scalar @jobnums_running;
            for (my $split_num = 1; $split_num + 7 < $slurm_command_split_length; $split_num+=8) { #make array of job numbers currently running
                push @jobnums_running, $slurm_command_split[$split_num];
            }
            if ( grep(/^$jobnum$/, @jobnums_running)) {
                @status_array[$i] = "Running";
                @finish_times_array[$i] = "Not Completed";
            }
            #if job isn't still running
            if (@status_array[$i] ne "Running") { #if the analysis is not currently running
                #If analysis type is Calling/Filtering/Imputation
                if (@snp_calling_array[$i] eq "yes" && @imputation_array[$i] eq "yes") {
                    my @gbs_files;
                    #check for vcf file in calling folder
                    @gbs_files = glob("$path/snpcall/*x.vcf.gz");
                    if (@gbs_files) {
                        #set gbs error value to 0 (no error)
                        $gbs_error[$i] = 0;
                        #check if imputation completed
                        #then check if there were any errors during imputation by reading the beagle log file
                        @beagle_files = glob("$path/beagle/beagle.out.vcf*gz");
                        if (@beagle_files) { #first check if beagle output file exists
                            my $beagle_log;
                            my @beagle_log_path = glob("$path/beagle/beagle_log*.out");
                            if (@beagle_log_path) {#if there is a log file
                                my $beagle_log_path = "$path/beagle/beagle_log.out";
                                open $beagle_log, '<', $beagle_log_path or die "Could not open file '$beagle_log_path'";
                                while (my $line = <$beagle_log>) {
                                    if ($line =~ /ERROR/ | $line =~ /Exception/ | $line =~ /Illegal/ | $line =~ /Terminating/ ) {
                                        @finish_times_array[$i] = "Not Completed";
                                        $beagle_error[$i] = 1;
                                    } else {
                                        $beagle_error[$i] = 0;
                                        my @beagle_complete_files = glob("$path/beagle/beagle_complete*");
                                        if (@beagle_complete_files) {
                                            #if no errors and beagle complete file exists:
                                            #check when beagle complete file was last edited
                                            $fh="$path/beagle/beagle_complete";
                                            $epoch_timestamp=(stat($fh))[9];
                                            $timestamp=scalar localtime($epoch_timestamp);
                                            @finish_times_array[$i] = $timestamp;
                                        } else {
                                            $fh="$path/beagle/beagle.out.vcf.gz";
                                            $epoch_timestamp=(stat($fh))[9];
                                            $timestamp=scalar localtime($epoch_timestamp);
                                            @finish_times_array[$i] = $timestamp;
                                        }
                                    }
                                }
                            } else { #if there's no log file
                                my @beagle_complete_files = glob("$path/beagle/beagle_complete*");
                                if (@beagle_complete_files) {
                                    #if no errors and beagle complete file exists:
                                    #check when beagle complete file was last edited
                                    $fh="$path/beagle/beagle_complete";
                                    $epoch_timestamp=(stat($fh))[9];
                                    $timestamp=scalar localtime($epoch_timestamp);
                                    @finish_times_array[$i] = $timestamp;
                                    $beagle_error[$i] = "N/A";
                                } else {
                                    $fh="$path/beagle/beagle.out.vcf.gz";
                                    $epoch_timestamp=(stat($fh))[9];
                                    $timestamp=scalar localtime($epoch_timestamp);
                                    @finish_times_array[$i] = $timestamp;
                                    $beagle_error[$i] = "N/A";
                                }
                            }
                        } else { #if there are no beagle result files
                            @finish_times_array[$i] = "N/A";
                            $beagle_error[$i] = "N/A";
                        }
                    } else { #If there's no calling result fill in the column with N/A and set gbs error to 1 unless the analysis was cancelled
                        my @glob_slurm=glob("$ui_log/slurm*");
                        if (@glob_slurm) {
                            $gbs_error[$i] = 1;
                            $beagle_error[$i] = 0;
                            @finish_times_array[$i] = "Not Completed";
                            my $ui_log;
                            my $ui_log_path = @glob_slurm[0];
                            open $ui_log, '<', $ui_log_path or die "Could not open file '$ui_log_path'";
                            while (my $line = <$ui_log>) {
                                #check if the analysis was cancelled
                                if ($line =~ /CANCELLED/ ) {
                                    @finish_times_array[$i] = "Not Completed";
                                    @status_array[$i] = "Cancelled";
                                    $gbs_error[$i] = 0;
                                }
                            }
                        }
                    }
                } elsif (@snp_calling_array[$i] eq "no" && @imputation_array[$i] eq "yes") {
                    $gbs_error[$i] = 0;
                    #set gbs error value to 0 (no error)
                    #check if imputation completed
                    #then check if there were any errors during imputation by reading the beagle log file
                    my @beagle_files = glob("$path/beagle/beagle.out.vcf*gz");
                    if (@beagle_files) { #first check if beagle output file exists
                        my $beagle_log;
                        my @beagle_log_path = glob("$path/beagle/beagle_log*.out");
                        if (@beagle_log_path) {#if there is a log file
                            my $beagle_log_path = "$path/beagle/beagle_log.out";
                            open $beagle_log, '<', $beagle_log_path or die "Could not open file '$beagle_log_path'";
                            while (my $line = <$beagle_log>) {
                                if ($line =~ /ERROR/ | $line =~ /Exception/ | $line =~ /Illegal/ | $line =~ /Terminating/ ) {
                                    @finish_times_array[$i] = "N/A";
                                    $beagle_error[$i] = 1;
                                } else {
                                    $beagle_error[$i] = 0;
                                    my @beagle_complete_files = glob("$path/beagle/beagle_complete*");
                                    if (@beagle_complete_files) {
                                        #if no errors and beagle complete file exists:
                                        #check when beagle complete file was last edited
                                        $fh="$path/beagle/beagle_complete";
                                        $epoch_timestamp=(stat($fh))[9];
                                        $timestamp=scalar localtime($epoch_timestamp);
                                        @finish_times_array[$i] = $timestamp;
                                    } else {
                                        $fh="$path/beagle/beagle.out.vcf.gz";
                                        $epoch_timestamp=(stat($fh))[9];
                                        $timestamp=scalar localtime($epoch_timestamp);
                                        @finish_times_array[$i] = $timestamp;
                                    }
                                }
                            }
                        } else { #if there's no beagle log file
                            my @beagle_complete_files = glob("$path/beagle/beagle_complete*");
                            if (@beagle_complete_files) {
                                #if no errors and beagle complete file exists:
                                #check when beagle complete file was last edited
                                $fh="$path/beagle/beagle_complete";
                                $epoch_timestamp=(stat($fh))[9];
                                $timestamp=scalar localtime($epoch_timestamp);
                                @finish_times_array[$i] = $timestamp;
                                $beagle_error[$i] = "N/A";
                            } else {
                                $fh="$path/beagle/beagle.out.vcf.gz";
                                $epoch_timestamp=(stat($fh))[9];
                                $timestamp=scalar localtime($epoch_timestamp);
                                @finish_times_array[$i] = $timestamp;
                                $beagle_error[$i] = "N/A";
                            }
                        }
                    } else { #if there are no beagle result files
                        $beagle_error[$i] = "N/A";
                        @finish_times_array[$i] = "N/A";
                    }
                }
                elsif (@snp_calling_array[$i] eq "yes" && @imputation_array[$i] eq "no") {
                    $beagle_error[$i] = 0;
                    my @files = glob("$path/snpcall/*x.vcf.gz");
                    #check for vcf file in calling folder
                    if (@files) {
                        $gbs_error[$i] = 0;
                        $fh="$path/Analysis_Complete*";
                        my @analysis_complete = glob($fh);
                        if (@analysis_complete) {
                            $fh="$path/Analysis_Complete";
                            $epoch_timestamp=(stat($fh))[9];
                            $timestamp=scalar localtime($epoch_timestamp);
                            push @finish_times_array, $timestamp;
                        }
                        else {
                            my @glob=glob("$path/snpcall/*x.vcf.gz");
                            $fh=@glob[0];
                            my $epoch_timestamp=(stat($fh))[9];
                            my $timestamp=scalar localtime($epoch_timestamp);
                            push @finish_times_array, $timestamp;
                        }
                    }
                    else { #If there are no calling results fill in the column with Not Completed and set gbs error to 1 unless the analysis was cancelled
                        my @glob_slurm=glob("$ui_log/slurm*");
                        if (@glob_slurm) {#If there's a slurm log
                            $gbs_error[$i] = 1;
                            $beagle_error[$i] = 0;
                            @finish_times_array[$i] = "Not Completed";
                            my $ui_log;
                            my $ui_log_path = @glob_slurm[0];
                            open $ui_log, '<', $ui_log_path or die "Could not open file '$ui_log_path'";
                            while (my $line = <$ui_log>) {
                                #check if the analysis was cancelled and if so change error value
                                if ($line =~ /CANCELLED/ ) {
                                    @finish_times_array[$i] = "Not Completed";
                                    @status_array[$i] = "Cancelled";
                                    $beagle_error[$i] = 0;
                                    $gbs_error[$i] = 0;
                                }
                            }
                        } else { #else if there's no slurm log
                            $gbs_error[$i] = 1;
                            $beagle_error[$i] = 0;
                            @status_array[$i] = "Not Run";
                            @finish_times_array[$i] = "Not Completed";
                        }
                    }
                } else { #If none of the above combinations are true
                    @finish_times_array[$i] = "N/A";
                    $gbs_error[$i] = "N/A";
                    $beagle_error[$i] = "N/A";
                }
                if (@finish_times_array[$i]=~/[0-9]:[0-9]/) {
                    @status_array[$i] = "Completed";
                }
                elsif ($gbs_error[$i] eq 1) {
                    @status_array[$i] = "Calling/Filtering Error";
                    @finish_times_array[$i] = "Not Completed";
                }
                elsif ($beagle_error[$i] eq 1) {
                    @status_array[$i] = "Imputation Error";
                    @finish_times_array[$i] = "Not Completed";
                } else { #If the analysis did not complete but there are no errors
                    my @slurm_out_glob = glob("$ui_log/slurm*.out");
                    if (@slurm_out_glob) {
                        my $file_path = $ui_log."/slurm-$jobnum".".out";
                        my $slurm_file;
                        open $slurm_file, '<', $file_path or die "Could not open file '$slurm_file'";
                        @status_array[$i] = "N/A";
                        while (my $line = <$slurm_file>) {
                            #check if the analysis was cancelled and if so change error value
                            if ($line =~ /slurmstepd/ && $line =~ /JOB $jobnum/ && $line =~ /CANCELLED/) {
                                @status_array[$i] = "Canceled";
                                @finish_times_array[$i] = "Not Completed";
                            }
                        }
                    } else { #If there's no slurm.out file
                        @status_array[$i] = "Job did not run";
                        @finish_times_array[$i] = "Not Completed";
                    }
                }
            }
        } else { #If there's no job number
            @status_array[$i] = "Job did not run";
            @finish_times_array[$i] = "Not Completed";
        }
    }

    #format finish times
    my %finish_times_hash;
    $finish_times_hash{ $username } = \@finish_times_array;
    my $finish_times_json= encode_json \%finish_times_hash;

    #format analysis status
    my %status_hash;
    $status_hash{ $username } = \@status_array;
    my $status_json= encode_json \%status_hash;

    #download links
    #same link as in email
    my @download_array;
    for (my $i = 0; $i < $analysis_folders; $i++) {
        my $folder = @analysis_folders[$i];
        my $download_link = "https://gbsappui.breedbase.org/results/".$username."/"."$folder"."/analysis_results.tar.gz";
        my $download_zipfile = "/gbsappui/root/results/$username/$folder/analysis_results.tar.gz";
        if (-e $download_zipfile) {
            @download_array[$i] = $download_link;
        }
        else {
            @download_array[$i] = "N/A";
        }
    }
    #https://gbsappui.breedbase.org/results/lockrow/MG4v/analysis_results.tar.gz
    #format download links
    my %download_hash;
    $download_hash{ $username } = \@download_array;
    my $download_json= encode_json \%download_hash;

    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{file_list_json}=$file_list_json;
    $c->stash->{refs_json}=$refs_json;
    $c->stash->{contact_email}=$contact_email;
    $c->stash->{contact_name}=$contact_name;
    $c->stash->{username}=$username;
    $c->stash->{analysis_folders_json}=$analysis_folders_json;
    $c->stash->{analysis_list_json}=$analysis_list_json;
    $c->stash->{analysis_types_json}=$analysis_types_json;
    $c->stash->{start_times_json}=$start_times_json;
    $c->stash->{finish_times_json}=$finish_times_json;
    $c->stash->{status_json}=$status_json;
    $c->stash->{download_json}=$download_json;
    $c->stash->{template}="choose_pipeline.mas";
}

sub choose_ref:Path('/choose_ref') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $refgenomes_json = $c->config->{refgenomes_json};
    my $refgenomes_labels_json = $c->config->{refgenomes_labels_json};
    my $ref_path = "nopath";
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    my $sgn_token=$c->req->param('sgn_token_callfilter');
    my $scp_files = $c->req->param('scp_files');
    $c->stash->{sgn_token} = $sgn_token;
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{refgenomes_json}=$refgenomes_json;
    $c->stash->{refgenomes_labels_json}=$refgenomes_labels_json;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{scp_files}=$scp_files;
    $c->stash->{template}="choose_ref.mas";
}

sub choose_fastq:Path('/choose_fastq') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $ref_path=$c->req->param('ref_path');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    my $sgn_token=$c->req->param('sgn_token');
    my $username = "nousername";
    my $scp_files = $c->req->param('scp_files');
    $c->stash->{username} = $username;
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{scp_files}=$scp_files;
    $c->stash->{template}="choose_fastq.mas";
}

sub choose_impute_vcf:Path('/choose_impute_vcf') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    my $sgn_token=$c->req->param('sgn_token_impute');
    my $username = "nousername";
    my $scp_files = $c->req->param('scp_files_impute');
    $c->stash->{username} = $username;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{scp_files}=$scp_files;
    $c->stash->{template}="choose_impute_vcf.mas";
}

sub impute:Path('/impute'): Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $username=$c->req->param('username');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    #get list of analysis folders
    my $raw_analysis_folders = `ls /results/$username`;
    my @analysis_folders = split("\n", $raw_analysis_folders);
    #remove any starting or trailing white spaces
    foreach my $folder (@analysis_folders) {
        $folder =~ s/^\s+|\s+$//g;
    }

    #for each analysis
    #grab analysis name from text file
    my @analysis_name_array;
    foreach my $folder (@analysis_folders) {
        my $analysis_name_string;
        my @text_file_exists = glob("/results/$username/$folder/analysis_info*.txt");
        if (@text_file_exists) {
            my $file_path = "/results/$username/$folder/analysis_info.txt";
            my $info_file;
            open $info_file, '<', $file_path or die "Could not open file '$info_file'";
            while (my $line = <$info_file>) {
                chomp $line;
                if ($line =~ /^Analysis Name:/) {
                    $analysis_name_string = $line;
                    $analysis_name_string =~ s/Analysis Name: //;
                    chomp $analysis_name_string;
                    push(@analysis_name_array, $analysis_name_string);
                }
            }
        }
        else {
            push(@analysis_name_array, "Analysis Name Missing");
        }
    }

    #Make a hash and encode it into json format for analysis names
    my %analyses_names_of;
    $analyses_names_of{ $username } = \@analysis_name_array;
    my $analysis_list_json = encode_json \%analyses_names_of;

    #make email and analysis variables
    my $email_address = "noemail";
    my $analysis_name = "noname";

    #make gbsapp and beagle running variables
    my $run_beagle = 1;

    #setup data directory and project directory
    my $data_dir = "/results/".$username."/";
    #Make username directory if it doesn't exist already
    if (! -d $data_dir) {
        make_path($data_dir);
    }
    my $dirname_template = 'XXXX';
    my $projdir_object = File::Temp->newdir ($dirname_template,      DIR => $data_dir, CLEANUP => 0);
    my $projdir = $projdir_object->{DIRNAME};
    my $projdir_orig = $projdir;
    $projdir=~s/\;//g; #don't allow ';' in project directory name
    $projdir=~s/_//g; #don't allow '_' in project directory name
    $projdir_object->{DIRNAME} = $projdir;
    if ($projdir_orig ne $projdir) {
        print STDERR "Original name was not acceptable ($projdir_orig). Changing it to $projdir. Removing $projdir_orig .\n";
        `rm -rf $projdir_orig`;
    }

    #make gbsappui_slurm_log folder
    my $slurmlogdir="/gbsappui_slurm_log/";
    make_path($projdir.$slurmlogdir);

    #parse and copy chosen input files into project directory and name them appropriately
    my $chosen_files = $c->req->param("chosen_files_final");
    my @chosen_files_array = split(",", $chosen_files);
    print STDERR "My chosen files are \n";
    print STDERR Dumper @chosen_files_array;
    print STDERR "Moving files to data folder \n";
    foreach my $chosen_file (@chosen_files_array) {
        print STDERR "working on \n";
        print STDERR Dumper $chosen_file;
        fcopy("/scp_uploads/".$username."/".$chosen_file,$projdir."/".$chosen_file);
        `chmod 777 $projdir/$chosen_file`;
    }

    my $sgn_token=$c->req->param('sgn_token');
    $c->stash->{email_address} = $email_address;
    $c->stash->{analysis_name} = $analysis_name;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{projdir} = $projdir;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{username} = $username;
    $c->stash->{analysis_list_json}=$analysis_list_json;
    $c->stash->{template} = "impute.mas";
}

sub submit:Path('/submit') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};

    #make email variable
    my $email_address = "noemail";
    my $analysis_name = "noname";

    #make gbsapp and beagle running variable
    my $run_beagle = "nobeagle";

    #setup data directory and project directory
    my $ref_path=$c->req->param('ref_path');
    my $username = $c->req->param('username');
    my $data_dir = "/results/".$username."/";
    #Make username directory if it doesn't exist already
    if (! -d $data_dir) {
        make_path($data_dir);
    }
    my $dirname_template = 'XXXX';
    my $projdir_object = File::Temp->newdir ($dirname_template,      DIR => $data_dir, CLEANUP => 0);
    my $projdir = $projdir_object->{DIRNAME};
    my $projdir_orig = $projdir;
    print STDERR "Original proj dir is $projdir_orig \n";
    $projdir=~s/\;//g; #don't allow ';' in project directory name
    $projdir=~s/_//g; #don't allow '_' in project directory name
    $projdir_object->{DIRNAME} = $projdir;
    print STDERR "New proj dir is $projdir \n";
    if ($projdir_orig ne $projdir) {
        print STDERR "Original name was not acceptable ($projdir_orig). Changing it to $projdir. Removing $projdir_orig .\n";
        `rm -rf $projdir_orig`;
    }
    my $template="/project/";
    rcopy($template,$projdir) or die $!;
    print STDERR "Copying $ref_path to $projdir/refgenomes/ \n";
    rcopy($ref_path,$projdir."/refgenomes/") or die $!;

    #parse and copy chosen input files into project directory and name them appropriately
    my $chosen_files = $c->req->param("chosen_files_final");
    my @chosen_files_array = split(",", $chosen_files);
    print STDERR "My chosen files are \n";
    print STDERR Dumper @chosen_files_array;
    print STDERR "Moving files to data folder \n";
    foreach my $chosen_file (@chosen_files_array) {
        print STDERR "working on \n";
        print STDERR Dumper $chosen_file;
        fcopy("/scp_uploads/".$username."/".$chosen_file,$projdir."/samples/".$chosen_file);
        `chmod 777 $projdir/samples/$chosen_file`;
    }

    #if biparental: edit config file to include p1 (maternal parent) and p2 (paternal parent)
    # my $biparental;
    # if (my $biparental==1) {
    #     console.log("biparental");
    #     # edit config file
    # }

    my $sgn_token=$c->req->param('sgn_token');
    $c->stash->{email_address} = $email_address;
    $c->stash->{analysis_name} = $analysis_name;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{projdir} = $projdir;
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{username} = $username;
    $c->stash->{template} = "submit.mas";
}

sub analyze:Path('/analyze') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
    $c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
    $c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    my $projdir=$c->req->param('projdir');
    my $run_beagle=$c->req->param('run_beagle');
    my $email_address=$c->req->param('email_address');
    my $analysis_name=$c->req->param('analysis_name');
    my $run_gbsapp=$c->req->param('run_gbsapp');

    #remove extraneous spaces from email address
    $email_address=~ s/\s//g;

    $projdir=$projdir."/";
    my $ui_log=$projdir."gbsappui_slurm_log";
    `cd $ui_log && bash /gbsappui/devel/submit_gbsappui.sh $projdir $run_beagle $email_address $gbsappui_domain_name $run_gbsapp $analysis_name` or die "Didn't run: $!\n";
    my $sgn_token=$c->req->param('sgn_token');
    $c->stash->{email_address} = $email_address;
    $c->stash->{analysis_name} = $analysis_name;
    $c->stash->{projdir} = $projdir;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{run_gbsapp} = $run_gbsapp;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{template}="analyze.mas";
}

sub cancel:Path('/cancel') : Args(0) {
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    my $email_address=$c->req->param('email_address');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    #get job number
    #my $jobnum=$c->req->param('jobnum') #if analyze jobnum code is integrated

    #cancellation
    #cancel gbs job if slurm file(s) exists in projdir
    my @slurm_glob = glob("$projdir*slurm*");
    my $jobnum;
    my $ui_log=$projdir."gbsappui_slurm_log";
    if (@slurm_glob) {
        #pull out the job number from the slurm.out filename
        my $slurm_filename=`cd $ui_log; ls slurm*`;
        my @filename_array = split /[.-]/, $slurm_filename;
        $jobnum = @filename_array[1];
        #remove any starting or trailing white spaces
        $jobnum =~ s/^\s+|\s+$//g;
        #cancel job number
        print STDERR "Canceling Job Number(s) $jobnum \n";
        `scancel $jobnum`;
    }

    #cancel full ui job
    print STDERR "Canceling Job Number $jobnum \n";
    `scancel $jobnum`;

    #eventually prompt: discard analysis or would you like to return to it later?
    #eventually option to rerun/start where left off
    #redirect to start when analysis complete
    my $sgn_token=$c->req->param('sgn_token_cancel');
    my $username=$c->req->param('username_cancel');
    $c->stash->{projdir} = $projdir;
    $c->stash->{email_address} = $email_address;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{username}=$username;
    $c->stash->{template}="cancel.mas";
}

sub delete:Path('/delete') : Args(0) {
    my $self=shift;
    my $c=shift;
    my $analysis_folder = $c->req->param('analysis_folder_delete');
    my $sgn_token=$c->req->param('sgn_token_delete');
    my $username=$c->req->param('username_delete');
    if ($analysis_folder) {
        #Check if analysis is still running and cancel gbs job if slurm file(s) exists in projdir
        my $projdir = "/results/$username/$analysis_folder/";
        my $jobnum_gbs;
        my $jobnum_full_ui;
        my @slurm_glob = glob("$projdir*slurm*");
        #cancel gbs job
        if (@slurm_glob) {
            my $slurm_filename=`cd $projdir; ls *slurm*.out`;
            my @filename_array = split /[.-]/, $slurm_filename;
            $jobnum_gbs = @filename_array[1];
            #remove any starting or trailing white spaces
            $jobnum_gbs =~ s/^\s+|\s+$//g;
            #cancel job number as long as it's running
            if (index(`squeue`, $jobnum_gbs) != -1) {
                print STDERR "Canceling Job Number $jobnum_gbs \n";
                `scancel $jobnum_gbs`;
            }
        }
        #cancel full ui job
        my $ui_log=$projdir."gbsappui_slurm_log";
        my @slurm_glob_ui = glob("$ui_log*slurm*.out");
        if (@slurm_glob_ui) {
            my $slurm_filename=`cd $ui_log; ls *slurm*.out`;
            my @filename_array = split /[.-]/, $slurm_filename;
            $jobnum_full_ui = @filename_array[1];
            #remove any starting or trailing white spaces
            $jobnum_full_ui =~ s/^\s+|\s+$//g;
            #cancel job number as long as it's running
            if (index(`squeue`, $jobnum_full_ui) != -1) {
                print STDERR "Canceling Job Number $jobnum_full_ui \n";
                `scancel $jobnum_full_ui`;
            }
        }
        # delete results folder
        `rm -rf /results/$username/$analysis_folder`;
        #delete zipped folder
        `rm -rf /gbsappui/root/results/$username/$analysis_folder`;
    }
    else {
        print STDERR "No analysis folder provided";
    }
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{username}=$username;
    $c->stash->{template}="delete.mas";
}

sub results:Path('/results') : Args(0) {
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    my $email_address=$c->req->param('email_address');
    my $analysis_name=$c->req->param('analysis_name');
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    $c->stash->{projdir} = $projdir;
    $c->stash->{email_address} = $email_address;
    $c->stash->{analysis_name} = $analysis_name;
    $c->stash->{template}="results.mas";
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
}


1;
