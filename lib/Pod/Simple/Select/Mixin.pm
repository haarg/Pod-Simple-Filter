package Pod::Simple::Select::Mixin;
use strict;
use warnings;
use mro ();

our $VERSION = '0.001000';

sub selection {
  my $self = shift;
  $self->{_selection} = [];
  $self->add_selection(@_);
}

sub add_selection {
  my $self = shift;
  push @{ $self->{_selection} }, map compile_section_spec($_), @_;
  $self->{+__PACKAGE__}
    and delete $self->{+__PACKAGE__}{is_selected};
  return $self;
}

sub _handle_element_start {
  my $self = shift;
  my ($element_name, $attr) = @_;

  my $me = $self->{+__PACKAGE__} ||= {};

  return $self->next::method(@_)
    if $me->{in_replay};

  if ($element_name eq 'Document') {
    %$me = (
      section => [],
    );
  }

  if ($element_name eq 'Document' || $element_name eq 'encoding') {
    return $self->next::method(@_);
  }

  if ($element_name =~ /\Ahead(\d)\z/) {
    $me->{in_head} = {
      element => $element_name,
      level   => $1 + 0,
      attr    => $attr,
      events  => [],
      text    => '',
    };
  }

  if (my $head = $me->{in_head}) {
    push @{ $head->{events} }, [ '_handle_element_start', @_ ];
    return;
  }

  return
    if !$self->_is_selected;

  $self->next::method(@_);
}
sub _handle_text {
  my $self = shift;
  my ($text) = @_;

  my $me = $self->{+__PACKAGE__} ||= {};

  return $self->next::method(@_)
    if $me->{in_replay};

  if (my $head = $me->{in_head}) {
    push @{ $head->{events} }, [ '_handle_text', @_ ];
    $head->{text} .= $text;
    return;
  }

  return
    if !$self->_is_selected;

  $self->next::method(@_);
}

sub _handle_element_end {
  my $self = shift;
  my ($element_name, $attr) = @_;

  my $me = $self->{+__PACKAGE__} ||= {};

  return $self->next::method(@_)
    if $me->{in_replay};

  if (my $head = $me->{in_head}) {
    if ($element_name ne $head->{element}) {
      push @{ $head->{events} }, [ '_handle_element_end', @_ ];
      return;
    }
    delete $me->{in_head};

    my $section = $me->{section};
    splice @$section, $head->{level};
    $section->[$head->{level} - 1] = $head->{text};
    delete $me->{is_selected};

    if ($self->_is_selected) {
      local $me->{in_replay} = 1;
      for my $event (@{ $head->{events} }) {
        my ($method, @args) = @$event;
        $self->$method(@args);
      }
    }
    else {
      return;
    }
  }
  elsif (!$self->_is_selected) {
    return;
  }

  if ($element_name eq 'Document') {
    delete $self->{+__PACKAGE__};
  }

  $self->next::method(@_);
}

sub _is_selected {
  my $self = shift;

  my $me = $self->{+__PACKAGE__} ||= {};

  return $me->{is_selected}
    if exists $me->{is_selected};

  $me->{is_selected} = $self->match_section(@{ $me->{section} });
}

sub match_section {
  my $self = shift;
  my @sections = @_;

  my $selections = $self->{_selection} || [];

  return 1
    if !@$selections;

  SPEC: for my $spec ( @$selections ) {
    for my $i (0 .. $#$spec) {
      my $regex = $spec->[$i];
      my $heading = $sections[$i];
      $heading = ''
        if !defined $heading;
      next SPEC
        if $heading !~ $regex;
    }
    return 1;
  }

  return 0;
}

sub reinit {
  my $self = shift;
  delete $self->{+__PACKAGE__};
  $self->next::method(@_);
}

sub compile_section_spec {
  my $spec = shift;

  my @bad;
  my @parts;
  while ($spec =~ m{(?:\A|\G/)((?:[^/\\]|\\.)*)}g) {
    my $part = $1;
    $part =~ s{\\(.)}{$1}g;
    my $negate = $part =~ s{\A!}{};
    $part = '.*'
      if !length $part;

    my $re = eval {
      $negate ? qr{^(?!$part$)} : qr{^$part$};
    } or do {
      push @bad, qq{Bad regular expression /$part/ in "$spec": $@\n};
    };

    push @parts, $re;
  }
  die join '', @bad
    if @bad;
  return \@parts;
}

1;
