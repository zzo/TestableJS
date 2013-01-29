#!/usr/bin/perl

use JSON;
use Cwd qw(abs_path);
use XML::Writer;

my $f = abs_path(shift);

my @back = `jslint --json $f`;
my $res = decode_json(join '', @back);
my @errors;
foreach my $error (@{$res->[1]}) {
    if ($error->{id}) {
        push @errors, $error;
    }
}

my $xml = new XML::Writer();
$xml->startTag('jslint');
$xml->startTag('file', name => $res->[0]);
foreach my $error (@errors)
{
    $xml->emptyTag('issue',
        line => $error->{line},
        reason => $error->{reason},
        evidence => $error->{evidence}
    );
}
$xml->endTag('file');
$xml->endTag('jslint');
$xml->end;

exit(0);

