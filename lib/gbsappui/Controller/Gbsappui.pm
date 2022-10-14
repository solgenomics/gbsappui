package gbsappui::Controller::Gbsappui;
use Moose;
use Catalyst::Request::Upload;
use Data::Dumper;
use File::Temp qw/ :seekable /;
use File::Copy;

BEGIN {extends 'Catalyst::Controller'};

my $tempdir = File::Temp->newdir ();
#eventually make path below select_ref
sub upload_fastq:Path('/gbs_analysis') Args(0){
    my $self=shift;
    my $c=shift;
    my $upload=$c->req->upload("fastq_file");
    print STDERR "the tempdir is called $tempdir \n";
    $upload->copy_to($tempdir);
    copy("/gbsappui/gbs_input/",$tempdir);
    copy("$tempdir/$upload","$tempdir/gbs_input/samples/");
    print STDERR Dumper $upload;
    #my $size=$upload->size;
    #$c->stash->{size}=$size;
    $c->stash->{tempdir}=$tempdir;
    $c->stash->{template}="analyze.mas";
}

# sub select_ref:Path('/gbs_analysis') Args(0){
#     my $self=shift;
#     my $c=shift;
#     $c->stash->{template}="analyze.mas";
# }

sub gbs_analysis:Path('/submitted_analysis') Args(0){
    my $self=shift;
    my $c=shift;
    my $tempdir=$c->req->param("tempdir");
    $tempdir=~s/\;//g; #don't allow ; in tempfile
    `bash /GBSapp/GBSapp $tempdir/gbs_input`;
#    my $gbs_arg = "/gbsappui/gbs_input/";
#    system("bash", "/GBSapp/GBSapp","$gbs_arg");
#    print STDERR Dumper $refchoice;
    $c->stash->{template}="analyze.mas";
}
















1;
