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

BEGIN {extends 'Catalyst::Controller'};

sub choose_ref:Path('/choose_ref') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    $c->stash->{template}="choose_ref.mas";
}

sub upload_fastq:Path('/upload_fastq') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    # $c->stash->{projdir} = $projdir;
    # print STDERR "projdir is \n";
    # print STDERR $c->stash->{projdir}."\n";
    # print STDERR "c is \n";
    # print STDERR Dumper $c."\n";
#    $c->stash->{chosen_ref} = $chosen_ref;
#    my $chosen_ref = "manihot_esculenta_v8.0.fa.gz";
#    $c->stash->{chosen_ref}=$chosen_ref;
    $c->stash->{template}="upload_fastq.mas";
}

sub submit:Path('/submit') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
#    my $chosen_ref=$c->req->param('chosen_ref');
    my $data_dir = "/data/";
    my $projdir_object = File::Temp->newdir (DIR => $data_dir, CLEANUP => 0);
    $projdir_object=~s/\;//g; #don't allow ';' in project directory
    my $projdir = $projdir_object->{DIRNAME};
    my $template="/project/";
    rcopy($template,$projdir) or die $!;
    #need to edit so the directory is chosen based on instance somehow
#    rcopy("/refgenomes/Cassava/".$chosen_ref,$projdir."/refgenomes/") or die $!;
    # my %projdir=$c->req->param('projdir');
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
#    my $chosen_ref=$c->req->param("chosen_ref");
#    $chosen_ref->copy_to($projdir."/refgenomes");
    $c->stash->{projdir} = $projdir;
    $c->stash->{template} = "submit.mas";
}

sub analyze:Path('/analyze') : Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    $projdir=$projdir."/";
    print STDERR "projdir is $projdir \n";
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    `bash /GBSapp/GBSapp $projdir` or die "Didn't run: $!\n";
    print STDERR "Running GBSapp on $projdir \n";
    $c->stash->{projdir} = $projdir;
    $c->stash->{template}="analyze.mas";
}

sub cancel:Path('/cancel') : Args(0){
    my $self=shift;
    my $c=shift;
    print STDERR "Canceling analysis \n";
    my $jobnum="`squeue | tail -1 | `awk '{print $1}'``";
    print STDERR "canceling JOB num $jobnum \n";
    `scancel $jobnum`;
    $c->stash->{template}="cancel.mas";
}
















1;
