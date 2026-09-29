#!/usr/bin/perl
################################################################################
# Thumbnail generation script.  Part of the Image::Gallery suite.
#
# (c) 2006-2026 dleonard@dleonard.net
################################################################################
use strict;
use warnings;

use Getopt::Long;
Getopt::Long::Configure('bundling');

use Image::Gallery;

my $help = undef;
my %options = (dir => '/usr/local/image_gallery/test/images',
               ignore => 'x950',
               recursive => 1);
GetOptions(\%options,
           'dir=s',
           'format=s',
           'h|help' => \$help,
           'ignore=s',
           'percentage=s',
           'prepend=s',
           'quality=s',
           'recursive!',
           'width=s');

help() if $help;

eval {
 my $gallery = Image::Gallery->new(\%options);
 $gallery->thumbs(\%options);
 1;
} or do {
 my $err = $@;
 chomp $err;
 Image::Gallery->error($err) unless Image::Gallery->quiet();
 exit 1;
};

################################################################################
# help
################################################################################
sub help {
 print <<END;
generate_thumbs.pl
 --dir=DIRECTORY              # Directory to create thumbnails in
 --format=IMAGE_TYPE          # Type of image to create.  Default is same as
                                original image.
 -h|--help                    # Commandline usage
 --ignore=STRING              # Ignore files containing the specified substring
                                Default: x950
 --norecursive                # Turn off recursive directory following.
 --percentage=PERCENT         # Percent to scale to.  --percentage and --width
                                are mutually exclusive.  Default is 150 pixels.
 --prepend=STRING             # What to prepend each image with.  Default is
                                .thumb_
 --quality=PERCENT            # Quality level for jpg output.  Default is 75%.
 --recursive                  # Follow subdirectories creating thumbnails in
                                each.  On by default.
 --width                      # Width in pixels to scale thumbnails to.
                                Default is 150.

END

 exit 0;
}
