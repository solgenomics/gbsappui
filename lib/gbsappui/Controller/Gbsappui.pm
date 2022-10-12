package gbsappui::Controller::Gbsappui;
use Moose;
use Catalyst::Request::Upload;
use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;

BEGIN {extends 'Catalyst::Controller'};

sub upload_fastq:Path('/select_ref') Args(0){
    my $self=shift;
    my $c=shift;
    my $upload=$c->req->upload("fastq_file");
    my $tempdir = tempdir ( "upload_XXXXXX", DIR => "/data");
    print STDERR "tempdir $tempdir \n";
    $upload->copy_to($tempdir);
    copy("/gbsappui/gbs_input/*",$tempdir);
    print STDERR Dumper $upload;
    #my $size=$upload->size;
    #$c->stash->{size}=$size;
    $c->stash->{tempdir}=$tempdir;
    $c->stash->{template}="select_ref.mas";
}

sub gbs_analysis:Path('/gbs_analysis') Args(0){
    my $self=shift;
    my $c=shift;
    my $tempdir=$c->req->param("tempdir");
    $tempdir=~s/\;//g; #don't allow ; in tempfile
    `bash /GBSapp/GBSapp $tempdir`;
#    my $gbs_arg = "/gbsappui/gbs_input/";
#    system("bash", "/GBSapp/GBSapp","$gbs_arg");
#    print STDERR Dumper $refchoice;
    $c->stash->{template}="analyze.mas";
}
















1;
