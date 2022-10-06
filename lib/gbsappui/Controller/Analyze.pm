package gbsappui::Controller::Analyze;

use Moose;
#use Catalyst::Request::Upload;
use Data::Dumper;
BEGIN {extends 'Catalyst::Controller'};

sub gbs_analysis:Path('/gbs_analysis') Args(0){
    my $self=shift;
    my $c=shift;
    my $ref_upload=$c->req->upload("ref_file");
    my $gbs_arg = "/GBSapp/examples/proj";
    system("sh", "/GBSapp/GBSapp","$gbs_arg");
#    print STDERR Dumper $refchoice;
    $c->stash->{template}="analyze.mas";
}















1;
