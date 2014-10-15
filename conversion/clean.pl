#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use File::Basename;
use Try::Tiny;

use lib dirname(__FILE__);

use pre_xml;
use html_to_xml;
use post_xml;


# create a name for the clean file
my $pathname = "$ARGV[0]";
my($filename_no_ext, $dirs, $ext) = fileparse($pathname, qr/\.[^.]*/);
my $newpath = "$dirs/${filename_no_ext}_clean$ext";

print "converting $pathname...\n";

my $text;
try {
  $text = pre_xml::pre_xml($pathname);
} catch {
  die "pre_xml error for $pathname: $_\n";
};

try {
  $text = html_to_xml::html_to_xml($text);
} catch {
  die "html_to_xml error for $pathname: $_\n";
};

try {
  $text = post_xml::post_xml($text);
} catch {
  die "post_xml error for $pathname: $_\n";
};

open my $out, '>:encoding(UTF-8)', $newpath;
print $out $text;
close $out;
