#!/usr/bin/perl
# Thumbnail and web-size generation.
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GalleryTest qw(sample_dir);

use File::Temp qw(tempdir);
use File::Copy qw(copy);

use Test::More;
use Image::Gallery;

my $sample = sample_dir();

# --- thumbnail generation --------------------------------------------------
my $work = tempdir(CLEANUP => 1);
copy("$sample/havok_w1.jpg", "$work/havok_w1.jpg") or die "copy: $!";

Image::Gallery->new(dir => $work)->thumbs({width => 120});
my $thumb = "$work/.thumb_havok_w1.jpg";
ok(-f $thumb, 'thumbnail file created');
is((Image::Magick->new->Ping($thumb))[0], 120,
   'thumbnail scaled to requested width');

# --- web-size generation ---------------------------------------------------
Image::Gallery->new(dir => $work)->thumbs({width => 950, postpend => 'x950'});
my $web = "$work/havok_w1x950.jpg";
ok(-f $web, 'web-sized file created');
is((Image::Magick->new->Ping($web))[0], 950,
   'web-sized image scaled to requested width');

done_testing();
