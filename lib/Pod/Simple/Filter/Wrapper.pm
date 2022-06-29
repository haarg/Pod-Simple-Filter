package Pod::Simple::Filter::Wrapper;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

my $STATE_KEY = 'Pod::Simple::Filter';

my %skip_compose;

# we're acting as a pseudo-role :(
sub wrap {
  my $class = shift;
  my ($wrap_package) = @_;
  no strict 'refs';
  for my $method (sort grep !/::\z/ && defined &$_, keys %{__PACKAGE__.'::'}) {
    next
      if exists $skip_compose{$method};
    my $install_method = $method;
    my $to_install = \&$method;
    if ($install_method =~ s/\A_wrap_//) {
      my $to_wrap = $wrap_package->can($install_method)
        or die "$install_method not available in $wrap_package!";
      $to_install = $to_install->($to_wrap);
    }
    no warnings 'redefine';
    *{$wrap_package.'::'.$install_method} = $to_install;
  }
  return;
}

BEGIN {
  no strict 'refs';
  @skip_compose{
    grep !/::\z/ && defined &$_, keys %{__PACKAGE__.'::'}
  } = ();
}

sub include_sections {
  my $self = shift;
  return @{ $self->{_include_sections} ||= [] };
}

sub clear_include_sections {
  my $self = shift;

  $self->_uncache_filter_allowed;
  $self->{_include_sections} = [];
  return $self;
}

sub set_include_sections {
  my $self = shift;
  $self->clear_include_sections;
  $self->add_include_sections(@_);
  return $self;
}

sub add_include_sections {
  my $self = shift;
  my @new_filters = map +(ref $_ ? $_ : $self->compile_heading_spec($_)), @_;
  push @{ $self->{_include_sections} }, @new_filters;

  $self->_uncache_filter_allowed;
  return $self;
}

sub _wrap__handle_element_start {
  my $wrapped = shift;
  sub {
    my $self = shift;
    my ($element_name, $attr) = @_;

    my $me = $self->{$STATE_KEY} ||= {};

    return $self->$wrapped(@_)
      if $me->{in_replay};

    if ($element_name eq 'Document') {
      %$me = (
        current_headings => [],
      );
    }

    if ($element_name eq 'Document' || $element_name eq 'encoding') {
      return $self->$wrapped(@_);
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
      if !$self->_filter_allowed;

    $self->$wrapped(@_);
  };
}

sub _wrap__handle_text {
  my $wrapped = shift;
  sub {
    my $self = shift;
    my ($text) = @_;

    my $me = $self->{$STATE_KEY} ||= {};

    return $self->$wrapped(@_)
      if $me->{in_replay};

    if (my $head = $me->{in_head}) {
      push @{ $head->{events} }, [ '_handle_text', @_ ];
      $head->{text} .= $text;
      return;
    }

    return
      if !$self->_filter_allowed;

    $self->$wrapped(@_);
  }
}

sub _wrap__handle_element_end {
  my $wrapped = shift;
  sub {
    my $self = shift;
    my ($element_name, $attr) = @_;

    my $me = $self->{$STATE_KEY} ||= {};

    return $self->$wrapped(@_)
      if $me->{in_replay};

    if (my $head = $me->{in_head}) {
      if ($element_name ne $head->{element}) {
        push @{ $head->{events} }, [ '_handle_element_end', @_ ];
        return;
      }
      delete $me->{in_head};

      my $headings = $self->_current_headings;
      @$headings = (@{$headings}[0 .. $head->{level} - 2], $head->{text});
      $self->_uncache_filter_allowed;

      if ($self->_filter_allowed) {
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
    elsif (!$self->_filter_allowed) {
      return;
    }

    if ($element_name eq 'Document') {
      delete $self->{$STATE_KEY};
    }

    $self->$wrapped(@_);
  };
}

sub _uncache_filter_allowed {
  my $self = shift;
  my $me = $self->{$STATE_KEY}
    or return;
  delete $me->{filter_allowed};
}

sub _filter_allowed {
  my $self = shift;

  my $me = $self->{$STATE_KEY} ||= {};

  return $me->{filter_allowed}
    if exists $me->{filter_allowed};

  $me->{filter_allowed} = $self->match_headings(@{ $self->_current_headings });
}

sub _current_headings {
  my $self = shift;
  my $me = $self->{$STATE_KEY} ||= {};
  return $me->{current_headings};
}

sub match_headings {
  my $self = shift;
  my @headings = @_;

  my @selections = $self->include_sections;

  return 1
    if !@selections;

  SPEC: for my $spec ( @selections ) {
    for my $i (0 .. $#$spec) {
      my $regex = $spec->[$i];
      my $heading = $headings[$i];
      $heading = ''
        if !defined $heading;
      next SPEC
        if $heading !~ $regex;
    }
    return 1;
  }

  return 0;
}

sub _wrap_reinit {
  my $wrapped = shift;
  sub {
    my $self = shift;
    delete $self->{$STATE_KEY};
    $self->$wrapped(@_);
  };
}

sub compile_heading_spec {
  my $self = shift;
  my ($spec) = @_;

  my @bad;
  my @parts = $spec =~ m{(?:\A|\G/)((?:[^/\\]|\\.)*)}g;
  for my $part (@parts) {
    $part =~ s{\\(.)}{$1}g;
    my $negate = $part =~ s{\A!}{};
    $part = '.*'
      if !length $part;

    eval {
      $part = $negate ? qr{^(?!$part$)} : qr{^$part$};
      1;
    } or do {
      push @bad, qq{Bad regular expression /$part/ in "$spec": $@\n};
    };
  }
  die join '', @bad
    if @bad;
  return \@parts;
}

1;
__END__

=head1 NAME

Pod::Simple::Filter::Wrapper - Parent class for filtering Pod documents

=head1 SYNOPSIS

  package Pod::Simple::Filter::XHTML;
  use parent qw(Pod::Simple::XHTML);
  use Pod::Simple::Filter::Wrapper;
  Pod::Simple::Filter::Wrapper::wrap(__PACKAGE__);

=head1 DESCRIPTION

Can be used to add filtering to an arbitrary L<Pod::Simple> subclass. Operates
similar to a role, but without any prerequisites.

=head1 SUPPORT

See L<Pod::Simple::Filter> for support and contact information.

=head1 AUTHORS

See L<Pod::Simple::Filter> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Pod::Simple::Filter> for the copyright and license.

=cut
