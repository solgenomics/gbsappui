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
use Email::Sender::Simple;

BEGIN {extends 'Catalyst::Controller'};

sub choose_ref:Path('/choose_ref') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $ref_path = "nopath";
    $c->stash->{ref_path} = $ref_path;
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
    my $ref_path=$c->req->param('ref_path');
    print STDERR "ref path is $ref_path \n";
    my $data_dir = "/data/";
    my $projdir_object = File::Temp->newdir (DIR => $data_dir, CLEANUP => 0);
    $projdir_object=~s/\;//g; #don't allow ';' in project directory
    my $projdir = $projdir_object->{DIRNAME};
    my $template="/project/";
    rcopy($template,$projdir) or die $!;
    print STDERR "Copying $ref_path to $projdir/refgenomes/ \n";
    rcopy($ref_path,$projdir."/refgenomes/") or die $!;
    my $upload=$c->req->upload("fastq_file");
    # my $creq=$c->req;
    print STDERR "projdir is \n";
    print STDERR Dumper $projdir;
    # print STDERR "c req is \n";
    # print STDERR Dumper $creq;
    # print STDERR "fastq is \n";
    # print STDERR Dumper $upload;
#    my $chosen_ref=$c->req->param('chosen_ref');
#    print STDERR Dumper $chosen_ref;
    print STDERR "upload is $upload \n";
    $upload->copy_to($projdir."/samples/");
#    $chosen_ref->copy_to($projdir."/refgenomes");
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
        #when ($projdir/Analysis_Complete){ #check when syntax...
            #if Beagle option is checked run beagle afteranalysis is complete
            #email vcf file using Mail::Sendmail sendmail() and getting email using username or whatnot
            # if ($beagle==1) {
                #$gbs_output=$projdir."*vcf*"; #probably need a more specific name here
                #$beagle_output=$projdir."out.ref"
                #`java -jar /beagle/beagle.*.jar ref=$analysis_ref_path gt=$gbs_output out=$beagle_output` or die "Couldn't run Beagle on completed gbs analysis: $!\n";
                #when ($beagle_output) {
                    #email beagle output file using Mail::Sendmail sendmail() and getting email using username or whatnot
                #}
            # }
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
