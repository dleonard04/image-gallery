#!/usr/bin/perl
# Caption parsing from a .caption file.
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GalleryTest qw(sample_dir);

use Test::More;
use Image::Gallery;

my $cap = Image::Gallery::Caption->new(dir => sample_dir());
$cap->read();
is($cap->title('havok_w1.jpg'), 'Havok and Wolverine',
   'caption title parsed from .caption');
is($cap->medium('havok_w1.jpg'), 'Acrylic on paper',
   'caption medium parsed from .caption');

done_testing();
