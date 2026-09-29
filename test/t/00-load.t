#!/usr/bin/perl
# Module loads.
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GalleryTest;

use Test::More;

use_ok('Image::Gallery') or BAIL_OUT('Image::Gallery failed to load');

done_testing();
