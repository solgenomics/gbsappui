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
use Email::Stuffer;


BEGIN {extends 'Catalyst::Controller'};

sub choose_ref:Path('/choose_ref') : Args(0){
    my $self=shift;
    my $c=shift;
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    my $refgenomes_json = $c->config->{refgenomes_json};
    my $ref_path = "nopath";
    # Create and send the email in one shot
    (Email::Stuffer->from('awl67@cornell.edu')
    #need to replace this with email name based on logged in account
                  ->to('awl67@cornell.edu')
                  ->text_body('hello')
    #              ->attach_file('attachment.vcf')
                  ->send) or die "$!";
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
        print STDERR "double directories w/ different names: $projdir_orig and $projdir. Trying my best to remove $projdir_orig . Please check that only one is here. \n";
        `rm -rf $projdir_orig`;
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

    #if biparental: edit config file to include p1 (maternal parent) and p2 (paternal parent)
    # my $biparental;
    # if (my $biparental==1) {
    #     console.log("biparental");
    #     # edit config file
    # }

    my $run_beagle = 0;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{projdir} = $projdir;
    $c->stash->{ref_path} = $ref_path;
    $c->stash->{template} = "submit.mas";
}

# sub running {
#     #check for analysis completion
#     my $projdir = shift;
#     my $run_beagle = shift;
#     my $cancel_var = 0;
#     my $canceled = 0;
#     #check for analysis completion
#     until (-e "$projdir/Analysis_Complete" || $cancel_var == 1 ) {
#         #get cancel_var somehow
#         #if (something) {$cancel_var = 1};
#         if ($cancel_var == 1 && $canceled == 0) {
#             cancel($projdir);
#             print STDERR "Canceling analysis \n";
#             $canceled = 1;
#             return $canceled;
#         };
#     };
#     print STDERR "run beagle value is $run_beagle \n";
#
#     print STDERR "Initial Analysis Complete \n";
#     for my $vcf_file (glob("${projdir}/snpcall/*.vcf.gz")) {
#         if( -e $vcf_file ) {
#             print STDERR "$vcf_file (gbs output) exists \n"; }
#         else {
#             print STDERR "vcf file (gbs output) doesn't exist \n";
#         }
#         if ($run_beagle==1){
#             print STDERR "Beagle has been chosen \n";
#             my $beagle_output=$vcf_file."_beagle_output";
#             `java -Xmx50g -jar /beagle/beagle.*.jar gt=$vcf_file out=$beagle_output`;
#             print STDERR "Running Beagle \n";
#             my $cancel_var = 0;
#             until (-e $beagle_output) {
#                 if ($cancel_var == 1 && $canceled == 0) {
#                     cancel($projdir);
#                     print STDERR "Canceling beagle \n";
#                     $canceled = 1;
#                 }
#             };
#             #email beagle output file using Mail::Sendmail sendmail() and getting email using username or whatnot
#             print STDERR "Beagle analysis complete";
#         } else {
#             print STDERR "Beagle has not been chosen \n";
#         }
#     }
#     return $canceled;
#     return $cancel_var;
# }

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

sub analyze:Path('/analyze') : Args(0){
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    my $run_beagle=$c->req->param('run_beagle');
    print STDERR "run beagle value is $run_beagle \n";
    $projdir=$projdir."/";
    my $ui_log=$projdir."gbsappui_slurm_log";
    print STDERR "projdir is $projdir \n";
    $c->response->headers->header( "Access-Control-Allow-Origin" => '*' );
	$c->response->headers->header( "Access-Control-Allow-Methods" => "POST, GET, PUT, DELETE" );
	$c->response->headers->header( 'Access-Control-Allow-Headers' => 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Authorization');
    `cd $ui_log && bash /gbsappui/devel/submit_gbsappui.sh $projdir $run_beagle` or die "Didn't run: $!\n";
    #not doing the following because of the sleep/waiting in run gbsappui
    #Need to figure out when to email
    #maybe zip a results file here
    # Prepare the message
    # my $body = "Dear GBSApp user,
    #
    # Please find the vcf result file and associated information attached.
    #
    # All the best,
    # GBSapp";
    #
    # # Create and send the email in one shot
    # (Email::Stuffer->from('awl67@cornell.edu')
    #need to replace this with email name based on logged in account
    #               ->to('awl67@cornell.edu')
    #               ->text_body($body)
    # #              ->attach_file('attachment.vcf')
    #               ->send) or die "$!";
    print STDERR "Running GBSapp on $projdir \n";
    print STDERR "String is $projdir/snpcall/"."vcf.gz \n";

    $c->stash->{projdir} = $projdir;
    $c->stash->{run_beagle} = $run_beagle;
    $c->stash->{template}="analyze.mas";
}

sub cancel:Path('/cancel') : Args(0) {
    my $self=shift;
    my $c=shift;
    my $projdir=$c->req->param('projdir');
    #get job number
    #my $jobnum=$c->req->param('jobnum') #if analyze jobnum code is integrated

    #cancellation
    #cancel gbs job if slurm file(s) exists in projdir
    if (glob("$projdir*slurm*")) {
        my $jobnum=`cd $projdir; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk 'BEGIN { ORS=" "};{n=split(\$0,a,".");print a[1]}'`;
        #cancel job number
        print STDERR "Canceling Job Number(s) $jobnum \n";
        `scancel $jobnum`;
    }

    #cancel full ui job
    my $ui_log=$projdir."gbsappui_slurm_log";
    my $jobnum=`cd $ui_log; ls slurm* | awk '{n=split(\$0,a,"-");print a[2]}' | awk 'BEGIN { ORS=" "};{n=split(\$0,a,".");print a[1]}'`;
    #cancel job number
    print STDERR "Canceling Job Number(s) $jobnum \n";
    `scancel $jobnum`;

    # until (-e "$projdir/Analysis_Complete") {
    #     sleep;
    # };
    # print STDERR "Sleeping done \n";

    #eventually prompt: discard analysis or would you like to return to it later?
    #eventually option to rerun/start where left off
    #remove analysis folder
    #redirect to start when analysis complete
    $c->stash->{projdir} = $projdir;
    $c->stash->{template}="cancel.mas";
}

# cd .; ls slurm* | awk '{n=split($0,a,"-");print a[2]}' | awk '{n=split($0,a,".");print a[1]}'


1;
