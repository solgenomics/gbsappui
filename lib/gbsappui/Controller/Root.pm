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
    my $websites_json = $c->config->{websites_json};
    my $gbsappui_domain_name = $c->config->{gbsappui_domain_name};
    $c->stash->{websites_json}=$websites_json;
    $c->stash->{gbsappui_domain_name}=$gbsappui_domain_name;
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
