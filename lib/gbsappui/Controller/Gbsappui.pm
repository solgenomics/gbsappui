package gbsappui::Controller::Gbsappui;
use Moose;
use Catalyst qw/Session Session::Store::File Session::State::Cookie/;
use Catalyst::Request::Upload;
use Data::Dumper;
#use File::Temp qw/ :seekable /;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove rcopy_glob);
#use File::Find;
use JSON;

BEGIN {extends 'Catalyst::Controller'};

# sub get_user_name:Path('/') Args(0){
#     my $self=shift;
#     my $c=shift;
#     my $username="success";
#     print STDERR "username is $username\n";
#     $c->stash->{template}="index.mas";
# }

# sub index:Path('/') Args(0){
#     my $self=shift;
#     my $c=shift;
#     $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
# 	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
# 	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
# #    my $username=$c->req->param('username');
#     my $username="success";
#     $c->stash->{username};
#     $c->stash->{template}="index.mas";
# }

# sub login:Path('/login') Args(0){
#     my $self=shift;
#     my $c=shift;
#     $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
# 	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
# 	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
#     $c->stash->{template}="login.mas";
# }

sub upload_fastq:Path('/upload_fastq') Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $projdir = "/project/";
    print STDERR "project directory is $projdir \n";
    $projdir=~s/\;//g; #don't allow ; in project directory
    $c->stash->{template}="upload_fastq.mas";
}

sub submit:Path('/submit') Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $upload=$c->req->upload("fastq_file");
    #my $tempdir = File::Temp->newdir ();
    #print STDERR "the tempdir is called $tempdir \n";
    #my @files = glob "$source/*";m
    #rcopy_glob("$source/*", $tempdir) or die $!;
    #print STDERR "$source was copied to $tempdir \n";
    my $projdir = "/project/";
    print STDERR "project directory is $projdir \n";
    $projdir=~s/\;//g; #don't allow ; in project directory

    $upload->copy_to($projdir."samples") or die $!;
    print STDERR "upload is $upload \n";
    print STDERR "$upload was copied to $projdir"."samples \n";
    $c->stash->{template}="submit.mas";
    #old bits
    #my $size=$upload->size;
    #$c->stash->{size}=$size;
}

sub analyze:Path('/analyze') Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $upload=$c->req->upload("fastq_file");
    my $projdir = "/project/";
    `bash /GBSapp/GBSapp $projdir` or die "Didn't run: $!\n";
    print STDERR "Running GBSapp on $projdir \n";
#    my $gbs_arg = "/gbsappui/gbs_input/";
#    system("bash", "/GBSapp/GBSapp","$gbs_arg");
#    print STDERR Dumper $refchoice;
#    $c->stash->{username}=$username;
    $c->stash->{template}="analyze.mas";
}


















1;
