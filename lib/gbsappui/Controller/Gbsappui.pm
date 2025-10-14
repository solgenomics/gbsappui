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
    my $raw_file_list = `ls -R /scp_uploads/$username`;
    #retrieving list of scp files available for username
    my @file_list = split("\n", $raw_file_list);
    shift @file_list;
    my %files_of;
    $files_of{ $username } = \@file_list;
    my $file_list_json = encode_json \%files_of;
    #get list of analyses
    my $raw_analysis_folders = `ls /results/$username`;
    print STDERR "raw analysis folders are $raw_analysis_folders \n";
    my @analysis_folders = split("\n", $raw_analysis_folders);
    print STDERR "split analysis folders are @analysis_folders \n";
    my %analyses_names_of;
    $analyses_names_of{ $username } = \@analysis_folders;
    print STDERR "Hashed analysis names are \n";
    print STDERR Dumper %analyses_names_of;
    my $analysis_list_json = encode_json \%analyses_names_of;
    print STDERR "Analysis folders are @analysis_folders \n";
    $c->stash->{sgn_token}=$sgn_token;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{file_list_json}=$file_list_json;
    $c->stash->{analysis_list_json}=$analysis_list_json;
    $c->stash->{contact_email}=$contact_email;
    $c->stash->{contact_name}=$contact_name;
    $c->stash->{username}=$username;
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
    my $sgn_token=$c->req->param('sgn_token');
    my $scp_files = $c->req->param('scp_files');
    print STDERR $scp_files;
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
    my $sgn_token=$c->req->param('sgn_token_callfilter');
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
    print STDERR $scp_files;
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
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};

    #make email and analysis variables
    my $email_address = "noemail";
    my $analysis_name = "noname";

    #make gbsapp and beagle running variables
    my $run_beagle = 1;

    #setup data directory and project directory
    my $username = $c->req->param('username');
    print STDERR "Username is $username \n";
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
    print STDERR "Username is $username \n";
    my $data_dir = "/results/".$username."/";
    #Make username directory if it doesn't exist already
    if (! -d $data_dir) {
        make_path($data_dir);
    }
    print STDERR "data dir is $data_dir \n";
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
    print STDERR "Analysis name is $analysis_name \n";
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
    if (glob("$projdir*slurm*")) {
        my $jobnum=`cd $projdir; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk 'BEGIN { ORS=" "};{n=split(\$0,a,".");print a[1]}'`;
        #cancel job number
        print STDERR "Canceling Job Number(s) $jobnum \n";
        `scancel $jobnum`;
    }

    #cancel full ui job
    my $ui_log=$projdir."gbsappui_slurm_log";
    my $jobnum=`cd $ui_log; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk 'BEGIN { ORS=" "};{n=split(\$0,a,".");print a[1]}'`;
    #cancel job number
    print STDERR "Canceling Job Number(s) $jobnum \n";
    `scancel $jobnum`;

    #eventually prompt: discard analysis or would you like to return to it later?
    #eventually option to rerun/start where left off
    #redirect to start when analysis complete
    $c->stash->{projdir} = $projdir;
    $c->stash->{email_address} = $email_address;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
    $c->stash->{template}="cancel.mas";
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
