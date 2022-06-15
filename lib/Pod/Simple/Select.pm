package Pod::Simple::Select;
use strict;
use warnings;
use Pod::Simple::Select::Mixin;
use Pod::Simple::JustPod;
our @ISA = qw(Pod::Simple::Select::Mixin Pod::Simple::JustPod);

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

1;
__END__

=head1 NAME

Pod::Simple::Select - Select sections from a Pod document

=head1 SYNOPSIS

  use Pod::Simple::Select;

=head1 DESCRIPTION

A new module.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2022 the Pod::Simple::Select L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
