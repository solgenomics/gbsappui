use strict;
use warnings;

use gbsappui;

my $app = gbsappui->apply_default_middlewares(gbsappui->psgi_app);
$app;

