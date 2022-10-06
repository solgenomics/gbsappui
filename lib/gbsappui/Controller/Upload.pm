package gbsappui::Controller::Upload;

use Moose;
use Catalyst::Request::Upload;
use Data::Dumper;
BEGIN {extends 'Catalyst::Controller'};

sub upload_fastq:Path('/select_ref') Args(0){
    my $self=shift;
    my $c=shift;
    my $upload=$c->req->upload("fastq_file");
    $upload->copy_to('/')
    print STDERR Dumper $upload;
    #my $size=$upload->size;
    #$c->stash->{size}=$size;
    $c->stash->{template}="select_ref.mas";
}
















1;
