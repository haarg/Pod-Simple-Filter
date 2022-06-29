package Pod::Simple::Filter::C3;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use if "$]" < 5.010, 'MRO::Compat';
use mro qw(c3);
use Pod::Simple;
our @ISA = qw(Pod::Simple);

use Pod::Simple::Filter::Wrapper;
Pod::Simple::Filter::Wrapper->wrap(__PACKAGE__);

sub _handle_element_start {
  my $self = shift;
  $self->next::method(@_);
}

sub _handle_element_end {
  my $self = shift;
  $self->next::method(@_);
}

sub _handle_text {
  my $self = shift;
  $self->next::method(@_);
}

sub reinit {
  my $self = shift;
  $self->next::method(@_);
}

1;
__END__

=head1 NAME

Pod::Simple::Filter::C3 - Parent class for filtering Pod::Select subclasses

=head1 SYNOPSIS

  package Pod::Simple::Filter::XHTML;
  use Pod::Simple::Filter::C3;
  use Pod::Simple::XHTML;
  use mro 'c3';
  our @ISA = qw(Pod::Simple::Filter::C3 Pod::Simple::XHTML);

=head1 DESCRIPTION

Can be used as a parent class (via C3) to add filtering to arbitrary Pod::Simple
subclasses.

=head1 COMPATIBILITY

While the rest of Pod::Simple::Filter is meant to be compatible with perl 5.6
and newer, this module is only compatible with perl 5.10.

On older perl versions, this module is still usable if L<MRO::Compat> is
installed.

=head1 SUPPORT

See L<Pod::Simple::Filter> for support and contact information.

=head1 AUTHORS

See L<Pod::Simple::Filter> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Pod::Simple::Filter> for the copyright and license.

=cut
