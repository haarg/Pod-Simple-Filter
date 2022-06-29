package Pod::Simple::Filter::PodSelect;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use Pod::Simple::Filter;
our @ISA = qw(Pod::Simple::Filter);

use Exporter; BEGIN { *import = \&Exporter::import }
our @EXPORT = qw(podselect);

sub podselect {
  my (@files) = @_;
  my $parser = __PACKAGE__->new;
  my $output;
  my %opts;
  for my $file (@files) {
    if (ref $file && ref $file eq 'HASH') {
      my %opts = map {
        my $key = lc $_;
        $key =~ s{\A-}{};
        $key =~ s{\Ase[cl].*}{sections}s;
        $key => $file->{$_};
      } keys %$file;

      $output = $opts{output}
        if exists $opts{output};
      $parser->select(@{ $opts{sections} })
        if exists $opts{sections};
      next;
    }
    $parser->parse_from_file($file, $output);
  }
}

sub curr_headings {
  my $self = shift;
  my $headings = $self->_current_headings;
  return @_ ? $headings->[$_[0]] : @$headings;
}

sub select {
  my $self = shift;
  my (@specs) = @_;

  if (@specs && $specs[0] eq '+') {
    shift @specs;
  }
  else {
    $self->clear_include_sections;
  }

  for my $spec (@specs) {
    eval {
      $self->add_include_sections($spec);
      1;
    } or do {
      warn $@;
      warn qq{Ignoring section spec "$spec"!\n};
    };
  }
}

sub add_selection {
  my $self = shift;
  $self->add_include_sections(@_);
}

sub clear_selections {
  my $self = shift;
  $self->clear_include_sections;
}

# i dunno what this is, but provided for compatibility
sub is_selected {
  my $self = shift;
  my ($paragraph) = @_;

  my @headings = $self->curr_headings;

  if ($paragraph =~ /^=((?:sub)*)(?:head(?:ing)?|sec(?:tion)?)(\d*)\s+(.*?)\s*$/) {
    my $sub = length($1) / 3;
    my $level = $2 || 1;
    my $heading = $3;

    $level = 1 + $sub
      if $sub;

    splice @headings, $level - 1;

    $headings[$level - 1] = $heading;
  }

  $self->match_headings(@headings);
}

sub match_section {
  my $self = shift;
  my @headings = @_;

  if (!@headings) {
    @headings = $self->curr_headings;
  }
  $self->match_headings(@headings);
}

1;
__END__

=head1 NAME

Pod::Simple::Filter::PodSelect - Pod::Select compatible API for Pod::Simple::Filter

=head1 SYNOPSIS

  use Pod::Simple::Filter::PodSelect;

  podselect(@filelist);

  podselect({-output => "tmp.out"}, @filelist);

  podselect({-sections => ["NAME|SYNOPSIS", "OPTIONS"]}, @filelist):

=head1 DESCRIPTION

Provides and interface fully compatible with L<Pod::Select>, but using
L<Pod::Simple::Filter> under the hood.

=head1 SUPPORT

See L<Pod::Simple::Filter> for support and contact information.

=head1 AUTHORS

See L<Pod::Simple::Filter> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Pod::Simple::Filter> for the copyright and license.

=cut
