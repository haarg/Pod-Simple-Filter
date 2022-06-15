package Pod::Simple::Select::PodSelect;
use strict;
use warnings;
use Pod::Simple::Select;
use Exporter;
*import = \&Exporter::import;
our @ISA = qw(Pod::Simple::Select);

our @EXPORT_OK = qw(podselect);

sub podselect {
  my (@files) = @_;
  my $parser = Pod::Simple::Select->new;
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
      $parser->selection(@{ $opts{sections} })
        if exists $opts{sections};
      next;
    }
    $parser->parse_from_file($file, $output);
  }
}

sub curr_headings {
  my $self = shift;
  my $me = $self->{+__PACKAGE__} || return undef;
  my $sections = $me->{section};
  return @_ ? $sections->[$_[0]] : @$sections;
}

sub select {
  my $self = shift;
  my (@specs) = @_;

  if (@specs && $specs[0] eq '+') {
    shift @specs;
  }
  else {
    $self->selection;
  }

  for my $spec (@specs) {
    eval {
      $self->add_selection($spec);
      1;
    } or do {
      warn $@;
      warn qq{Ignoring section spec "$spec"!\n};
    };
  }
}

sub clear_selections {
  my $self = shift;
  $self->selection;
}

sub is_selected {
  my $self = shift;
  my ($paragraph) = @_;

  my @sections = $self->curr_headings;

  if ($paragraph =~ /^=((?:sub)*)(?:head(?:ing)?|sec(?:tion)?)(\d*)\s+(.*?)\s*$/) {
    my $sub = length($1) / 3;
    my $level = $2 || 1;
    my $heading = $3;

    $level = 1 + $sub
      if $sub;

    splice @sections, $level - 1;

    $sections[$level - 1] = $heading;
  }

  $self->match_selection(@sections);
}

1;
