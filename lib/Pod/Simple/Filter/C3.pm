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

