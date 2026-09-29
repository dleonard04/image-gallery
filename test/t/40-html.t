#!/usr/bin/perl
# HTML output from templates and caption data.
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GalleryTest qw(sample_dir slurp);

use File::Temp qw(tempdir);
use File::Copy qw(copy);

use Test::More;
use Image::Gallery;

my $sample = sample_dir();

my $htmldir = tempdir(CLEANUP => 1);
copy("$sample/havok_w1.jpg", "$htmldir/havok_w1.jpg") or die "copy: $!";
copy("$sample/.caption",     "$htmldir/.caption")     or die "copy: $!";

my $gallery = Image::Gallery->new(dir          => $htmldir,
                                  template_dir => "$sample/templates");
$gallery->captions({existence => 1});
$gallery->html();

my $index = "$htmldir/index.html";
ok(-f $index, 'index.html generated');
my $html = slurp($index);
like($html, qr/havok_w1\.jpg/,       'html references the image');
like($html, qr/Havok and Wolverine/, 'html includes the caption title');

done_testing();
