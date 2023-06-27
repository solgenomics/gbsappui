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

sub upload_fastq:Path('/upload_fastq') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $data_dir = "/data/";
    my $projdir = File::Temp->newdir (DIR => $data_dir);
    $projdir=~s/\;//g; #don't allow ';' in project directory
    my $template="/project/";
    rcopy($template,$projdir) or die $!;
    #need to add copying refgenome chosen to projdir
    $c->stash->{projdir} = $projdir;
    $c->stash->{template}="upload_fastq.mas";
}

sub submit:Path('/submit') : Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param("projdir");
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $upload=$c->req->upload("fastq_file");
    $upload->copy_to($projdir."/samples");
    $c->stash->{projdir} = $projdir;
    $c->stash->{template} = "submit.mas";
}

sub analyze:Path('/analyze') : Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param("projdir");
    my $projdir=$projdir."/";
    # print STDERR "projdir is $projdir \n";
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    `bash /GBSapp/GBSapp $projdir` or die "Didn't run: $!\n";
    # print STDERR "Running GBSapp on $projdir \n";
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
