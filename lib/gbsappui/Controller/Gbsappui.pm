package gbsappui::Controller::Gbsappui;
use Moose;
use Catalyst qw/Session Session::Store::File Session::State::Cookie/;
use Catalyst::Request;
use Catalyst::Request::Upload;
use Data::Dumper;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove rcopy_glob);
use File::Spec;
use File::Temp qw/ :seekable /;
#use File::Find;
use JSON;
use Email::Stuffer;


BEGIN {extends 'Catalyst::Controller'};

sub choose_ref:Path('/choose_ref') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $refgenomes_json = $c->config->{refgenomes_json};
    my $ref_path = "nopath";
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{refgenomes_json}=$refgenomes_json;
    $c->stash->{template}="choose_ref.mas";
}

sub upload_fastq:Path('/upload_fastq') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $ref_path=$c->req->param('ref_path');
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{template}="upload_fastq.mas";
}

sub submit:Path('/submit') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');

    #make email variable
    my $email_address = "noemail";
    print STDERR "Email is $email_address \n";

    #make beagle running variable
    my $run_beagle = "nobeagle";
    print STDERR "Run beagle value is $run_beagle \n";

    #setup data directory and project directory
    my $ref_path=$c->req->param('ref_path');
    print STDERR "Submit Ref path is $ref_path \n";
    my $data_dir = "/data/";
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

    #move uploaded files into project directory and name them appropriately
    print STDERR " Uploading files to data folder \n";
    for my $upload ($c->req->upload("fastq")) {
        my $tempname=$upload->tempname();
        my $orig_upload = $upload->filename();
        print STDERR "orig name is $orig_upload \n";
        fmove($tempname,$projdir."/samples/".$orig_upload);
        `chmod 777 $projdir/samples/$orig_upload`;
    }

    #if biparental: edit config file to include p1 (maternal parent) and p2 (paternal parent)
    # my $biparental;
    # if (my $biparental==1) {
    #     console.log("biparental");
    #     # edit config file
    # }

    $c->stash->{email_address} = $email_address;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{projdir} = $projdir;
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{template} = "submit.mas";
}

sub analyze:Path('/analyze') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
    $c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
    $c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $projdir=$c->req->param('projdir');
    my $run_beagle=$c->req->param('run_beagle');
    my $email_address=$c->req->param('email_address');

    #remove extraneous spaces from email address
    $email_address=~ s/\s//g;

    $projdir=$projdir."/";
    my $ui_log=$projdir."gbsappui_slurm_log";
    print STDERR "Project directory is $projdir \n";
    `cd $ui_log && bash /gbsappui/devel/submit_gbsappui.sh $projdir $run_beagle $email_address` or die "Didn't run: $!\n";
    print STDERR "email is $email_address \n";
    $c->stash->{email_address} = $email_address;
    $c->stash->{projdir} = $projdir;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{template}="analyze.mas";
}

sub cancel:Path('/cancel') : Args(0) {
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    my $email_address=$c->req->param('email_address');
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
    $c->stash->{template}="cancel.mas";
}

sub results:Path('/results') : Args(0) {
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    my $email_address=$c->req->param('email_address');
    $c->stash->{projdir} = $projdir;
    $c->stash->{email_address} = $email_address;
    $c->stash->{template}="results.mas";
}




1;
