package gbsappui::Controller::REST;

use Moose;

# use File::Slurp;
# use URI::FromHash 'uri';
use Data::Dumper;
use JSON;
#get slurm package
#curling and perling
use Net::Curl::Easier;
use LWP::Simple;
use Catalyst::Controller::Rest;
BEGIN { extends 'Catalyst::Controller::REST' };

__PACKAGE__->config(
    default => 'application/json',
    stash_key => 'rest',
    map => { 'application/json' => 'JSON', 'text/html' => 'JSON'  },
    );



# sub ajax_analysis : Chained('/') PathPart('rest/analysis') CaptureArgs(1) {
#     my $self = shift;
#     my $c = shift;
#     my $analysis_id = shift;
#
#     $c->stash->{analysis_id} = $analysis_id;
# }

# sub list_analyses_table :Path('/rest/analysis_table') Args(0) {
#     my $self = shift;
#     my $c = shift;
#     my $username ="";
#     my @table;
#     foreach my $a (@analyses) {
#         my $name;
#         my $date;
#         my $type;
#         my $status;
#         my $run_time;
#         my $time_started;
#         my $time_completed;
#         my $download;
#         my $delete;
#         push @table, [
#             '<a href="/analyses/'.$a->get_trial_id().'">'.$a->name()."</a>",
#             $a->description(),
#             $name;
#             $date;
#             $type;
#             $status;
#             $run_time;
#             $time_started;
#             $time_completed;
#             $download;
#             $delete;
#         ];
#     }
#
#     #print STDERR Dumper(\@table);
#     $c->stash->{rest} = { data => \@table };
# }

# # =head1 retrieve_analysis_data()
# #
# # URL = /ajax/analysis/<analysis_id>/retrieve
# # returns data for the analysis_id in the following json structure:
# # {
# #     analysis_name
# #     analysis_description
# #     analysis_result_type
# #     dataset
# #     analysis_protocol
# #     accession_names
# #     data
# # }
# #
# # =cut
sub retrieve_analysis_data :Path('/rest/analysis_data') Args(0) {

}

sub retrieve_username :Path('/rest/username') Args(0) {
    #     my $self = shift;
    #     my $c = shift;
    my $cookie = "";
    my $username = "";
    #     $c->stash->{username} = $username;
}

sub retrieve_analysis_names :Path('/rest/analysis_names') Args(0) {

}

1;
