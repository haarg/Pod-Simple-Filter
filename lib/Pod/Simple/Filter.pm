package Pod::Simple::Filter;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use Pod::Simple::JustPod;
use Pod::Simple::Filter::Wrapper;

our @ISA = qw(
  Pod::Simple::JustPod
);

Pod::Simple::Filter::Wrapper->wrap(__PACKAGE__);

1;
__END__

=head1 NAME

Pod::Simple::Filter - Filter Pod documents compatibly with Pod::Select

=head1 SYNOPSIS

  use Pod::Simple::Filter;

  my $parser = Pod::Simple::Filter->new;
  $parser->set_filters('NAME');
  $parser->output_fh(\*STDOUT);
  $parser->parse_file('MyLib.pod');

=head1 DESCRIPTION

Filters Pod documents, outputting the 

=head1 FILTERS

Filters can be specified either as strings, or as array references of regular
expressions. When specified as strings, the format accepted is compatible with
L<Pod::Select>.

=head1 METHODS

=head2 set_filters

=head2 add_filters

=head2 clear_filters

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2022 the Pod::Simple::Filter L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
