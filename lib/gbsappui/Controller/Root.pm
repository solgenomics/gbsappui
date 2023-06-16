package gbsappui::Controller::Root;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

gbsappui::Controller::Root - Root Controller for gbsappui

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $referer = $c->req->param("referer") || $c->req->referer || "cassavabase.org";
    my $refgenomes_json = $c->config->{refgenomes_json};
    #my $projdir = $c->config->{projdir};
#    my $upload = $c->config->{upload};
    print STDERR "Refgenomes json:".$refgenomes_json."\n";
    my $refgenomes = decode_json($refgenomes_json);
    #my $cassavabase = (@{$refgenomes{'cassavabase'}});
    # my @refgenomes = @$refgenomes;
    # print STDERR "cassavabase is ".Dumper $cassavabase."\n";
    print STDERR "Decoded refgenomes:".Dumper $refgenomes;
    # my $files  = $refgenomes->{$referer};
    # print STDERR "HERE ARE THE FILES!";
#    print STDERR join ".", @$files;
    #make dropdown for refgenome here or in mason file
    $c->stash->{refgenomes}=$refgenomes;
    $c->stash->{template}="index.mas";
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}
=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
