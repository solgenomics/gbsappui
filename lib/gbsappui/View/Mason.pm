package gbsappui::View::Mason;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::HTML::Mason';

__PACKAGE__->config(
    interp_args => {
        comp_root => gbsappui->path_to('/mason/'),
        preamble => "use utf8; ",
    },
);

1;
