package gbsappui::Controller::Gbsappui;
use Moose;
use Catalyst qw/Session Session::Store::File Session::State::Cookie/;
use Catalyst::Request::Upload;
use Data::Dumper;
#use File::Temp qw/ :seekable /;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove rcopy_glob);
#use File::Find;

BEGIN {extends 'Catalyst::Controller'};

my $projdir = "/project";
#eventually make path below select_ref
sub upload_fastq:Path('/gbs_analysis') Args(0){
    my $self=shift;
    my $c=shift;
    #my $tempdir = File::Temp->newdir ();
    my $upload=$c->req->upload("fastq_file");
    #print STDERR "the tempdir is called $tempdir \n";
    #my @files = glob "$source/*";m
    #rcopy_glob("$source/*", $tempdir) or die $!;
    #print STDERR "$source was copied to $tempdir \n";
    $upload->copy_to("$projdir/samples/") or die $!;
    print STDERR "$upload was copied to $projdir/samples \n";
    #copy($upload,"$tempdir/samples/");
    print STDERR Dumper $upload;
    $c->stash->{projdir}=$projdir;
    $c->stash->{upload}=$upload;
    #$c->session->{projdir}=$projdir;
    #$c->session->{upload}=$upload;
    $c->stash->{template}="analyze.mas";
    #old bits
    #my $size=$upload->size;
    #$c->stash->{size}=$size;
}

# sub select_ref:Path('/gbs_analysis') Args(0){
#     my $self=shift;
#     my $c=shift;
#     $c->stash->{template}="analyze.mas";
# }

sub gbs_analysis:Path('/submitted_analysis') Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param("projdir");
    my $upload=$c->req->param("upload");
    $projdir=~s/\;//g; #don't allow ; in project directory
    `bash /GBSapp/GBSapp $projdir`;
    print STDERR "Running GBSapp on $upload in $projdir";
#    my $gbs_arg = "/gbsappui/gbs_input/";
#    system("bash", "/GBSapp/GBSapp","$gbs_arg");
#    print STDERR Dumper $refchoice;
    $c->stash->{template}="analyze.mas";
}
















1;
