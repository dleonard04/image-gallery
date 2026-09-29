#!/usr/bin/perl
# Incremental regeneration driven by the .md5sums cache.
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GalleryTest qw(sample_dir spew slurp);

use File::Temp qw(tempdir);
use File::Copy qw(copy);

use Test::More;
use Image::Gallery;

my $sample = sample_dir();

my $inc = tempdir(CLEANUP => 1);
copy("$sample/havok_w1.jpg", "$inc/havok_w1.jpg") or die "copy: $!";

# First run creates the thumb and records the source checksum.
Image::Gallery->new(dir => $inc)->thumbs({width => 120});
my $inc_thumb = "$inc/.thumb_havok_w1.jpg";
ok(-f "$inc/.md5sums", '.md5sums cache written');
is(Image::Gallery->readMd5sums($inc)->{'havok_w1.jpg'},
   Image::Gallery->md5("$inc/havok_w1.jpg"),
   '.md5sums records the source checksum');

# Mark the thumb so we can tell whether a later run rewrote it.
spew($inc_thumb, 'SENTINEL');

# Unchanged source: the existing thumb is left untouched.
Image::Gallery->new(dir => $inc)->thumbs({width => 120});
is(slurp($inc_thumb), 'SENTINEL', 'unchanged source is not rescaled');

# --force rescales even when the source is unchanged.
Image::Gallery->new(dir => $inc)->thumbs({width => 120, force => 1});
isnt(slurp($inc_thumb), 'SENTINEL', 'force rescales an unchanged source');

# A missing output is regenerated even when the source is unchanged.
unlink $inc_thumb;
Image::Gallery->new(dir => $inc)->thumbs({width => 120});
ok(-f $inc_thumb, 'missing output regenerated for an unchanged source');

# Changed source: the thumb is rescaled and the cache updated.
spew($inc_thumb, 'SENTINEL');
copy("$sample/ranma1.jpg", "$inc/havok_w1.jpg") or die "copy: $!";
Image::Gallery->new(dir => $inc)->thumbs({width => 120});
isnt(slurp($inc_thumb), 'SENTINEL', 'changed source is rescaled');
is(Image::Gallery->readMd5sums($inc)->{'havok_w1.jpg'},
   Image::Gallery->md5("$inc/havok_w1.jpg"),
   '.md5sums updated after a source change');

# Shared cache: a web-size run still creates its own output even though an
# earlier thumbs run already recorded the (unchanged) source.
my $shared = tempdir(CLEANUP => 1);
copy("$sample/havok_w1.jpg", "$shared/havok_w1.jpg") or die "copy: $!";
Image::Gallery->new(dir => $shared)->thumbs({width => 120});
Image::Gallery->new(dir => $shared)->thumbs({width => 950, postpend => 'x950'});
ok(-f "$shared/havok_w1x950.jpg",
   'web-sized output created despite shared unchanged-source cache');

done_testing();
