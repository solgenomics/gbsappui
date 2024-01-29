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
#use Email::Stuffer;

BEGIN {extends 'Catalyst::Controller'};

sub choose_ref:Path('/choose_ref') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $refgenomes_json = $c->config->{refgenomes_json};
    my $ref_path = "nopath";
    # #testing out email stuffer
    # # Prepare the message
    # my $body = "Dear friend
    #
    # here is a test email.
    # test email.
    # enjoy.
    #
    # me
    #
    # ME";
    #
    # # Create and send the email in one shot
    # (Email::Stuffer->from     ('amberlockrow@gmail.com'             )
    #               ->to       ('amberlockrow@gmail.com'     )
    # #
    #               ->text_body($body                     )
    # #              ->attach_file('attachment.gif' )
    #               ->send) or die $!;
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

    #setup data directory and project directory
    my $ref_path=$c->req->param('ref_path');
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
        print STDERR "Removing old directory name with excess characters \n";
        `rm -rf $projdir_orig` or die "Didn't run: $!\n";
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

    print STDERR "full req is:\n";
    print STDERR Dumper $c->req;
    #if biparental: edit config file to include p1 (maternal parent) and p2 (paternal parent)
    # my $biparental;
    # if (my $biparental==1) {
    #     console.log("biparental");
    #     # edit config file
    # }

    my $beagle = 1;
    $c->stash->{beagle} = $beagle;
    $c->stash->{projdir} = $projdir;
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{template} = "submit.mas";
}

sub analyze:Path('/analyze') : Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
#    my $beagle=$c->req->param('beagle');
#    my $analysis_ref_path=$projdir."/refgenomes/*fasta*";
#    print STDERR "current analysis refgenome location is $analysis_ref_path \n";
    $projdir=$projdir."/";
    print STDERR "projdir is $projdir \n";
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    `bash /GBSapp/GBSapp $projdir` or die "Didn't run: $!\n";
    print STDERR "Running GBSapp on $projdir \n";
    #detect when analysis complete
        #when ($projdir/Analysis_Complete) {
            #if ($projdir/snpcall/*x.vcf.gz) {
                #if Beagle option is checked run beagle after analysis is complete
                #email vcf file using Mail::Sendmail sendmail() and getting email using username or whatnot
                # if ($beagle) {
                    #$gbs_output=$projdir."*vcf*"; #probably need a more specific name here
                    #$beagle_output=$projdir."out.ref"
                    #`java -Xmx50g -jar /beagle/beagle.*.jar gt=$gbs_output out=$beagle_output` or die "Couldn't run Beagle on completed gbs analysis: $!\n";
                    #when ($beagle_output) {
                        #email beagle output file using Mail::Sendmail sendmail() and getting email using username or whatnot
                #}
            # }
            #}
        #}
            #`rm -rf $projdir`;
        #}

    #get jobnum for error detection
        #my $jobnum=`cd $projdir; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk '{n=split(\$0,a,".");print a[1]}'`;

    #detect error
        #if (! ((`cd $projdir; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk '{n=split(\$0,a,".");print a[1]}'`) = ($projdir)) {
            #email error
            #`rm -rf $projdir`;
        #}

    $c->stash->{projdir} = $projdir;
    #$c->stash->{jobnum} = $jobnum;
    $c->stash->{template}="analyze.mas";
}

sub cancel:Path('/cancel') : Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    #get job number
    #my $jobnum=$c->req->param('jobnum') #if analyze jobnum code is integrated
    my $jobnum=`cd $projdir; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk '{n=split(\$0,a,".");print a[1]}'`;
    #cancel job number
    print STDERR "Canceling Job Number $jobnum \n";
    `scancel $jobnum`;
    #eventually prompt: discard analysis or would you like to return to it later?
    #eventually option to rerun/start where left off
    #remove analysis folder
    `rm -rf $projdir`;
    $c->stash->{projdir} = $projdir;
    $c->stash->{template}="cancel.mas";
}









1;
