use strict;
use warnings;
use Test::More;
use Pod::Simple::Select;


sub convert {
  my ($pod, $select) = @_;

  my $out = '';
  my $parser = Pod::Simple::Select->new;
  $parser->output_string(\$out);
  $parser->selection(@$select);

  $parser->parse_string_document($pod);
  return $out;
}

sub compare {
  my ($in, $want, $select, $name) = @_;
  for my $pod ($in, $want) {
    if ($pod =~ /\A([\t ]+)/) {
      my $prefix = $1;
      $pod =~ s{^$prefix}{}gm;
    }
  }
  my $got = convert($in, $select);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is $got, $want, $name;
}

my $pod = 
compare <<'END_IN_POD', <<'END_OUT_POD', [ 'DESCRIPTION/guff' ];
  =head1 NAME

  =head2 welp

  =head3 hork

  =head1 DESCRIPTION

  =head2 guff

  =cut
END_IN_POD
  =pod

  =head2 guff

  =cut
END_OUT_POD

done_testing;
