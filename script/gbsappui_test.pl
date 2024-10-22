#!/usr/bin/env perl

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('gbsappui', 'Test');

1;

=head1 NAME

gbsappui_test.pl - Catalyst Test

=head1 SYNOPSIS

gbsappui_test.pl [options] uri

 Options:
   --help    display this help and exits

 Examples:
   gbsappui_test.pl https://gbsappui.breedbase.org/some_action
   gbsappui_test.pl /some_action

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst action from the command line.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
