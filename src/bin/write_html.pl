#!/usr/bin/perl
################################################################################
# Html generation script.  Part of the Image::Gallery suite.
#
# (c) 2006-2026 dleonard@dleonard.net
################################################################################
use strict;
use warnings;

use Getopt::Long;
Getopt::Long::Configure('bundling');
use Template::Constants ':all';

use Image::Gallery;

my $help = undef;
my %options = (css_dir => '/usr/local/image_gallery/test/css',
               dir => '/usr/local/image_gallery/test/images',
               recursive => 1,
               template_dir => '/usr/local/image_gallery/test/templates');

GetOptions(\%options,
           'allfiles',
           'css_dir=s',
           'debug',
           'dir=s',
           'existence',
           'favicon=s',
           'format=s',
           'h|help' => \$help,
           'percentage=s',
           'quality=s',
           'recursive!',
           'template_dir=s',
           'template_debug',
           'thumbs',
           'width=s');

help() if $help;

if ($options{template_debug}) {
 $options{debug} = DEBUG_ON | DEBUG_UNDEF | DEBUG_VARS | DEBUG_DIRS
                   | DEBUG_STASH | DEBUG_CONTEXT | DEBUG_PARSER | DEBUG_PLUGINS
                   | DEBUG_FILTERS | DEBUG_SERVICE;
}

eval {
 my $gallery = Image::Gallery->new(\%options);

 # Read in the .caption file(s)
 $gallery->captions(\%options);

 # Create thumbnails
 if ($options{thumbs}) {
  $gallery->thumbs(\%options);
 }

 my $css = $gallery->files({dir => $options{css_dir},
                            noassign => 1});

 # Create html pages for each directory
 $gallery->html(input => {favicon => $options{favicon},
                          stylesheet => $css});
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
write_html.pl
 --allfiles                   # Create a caption for all files in the directory
                                even if there isn't currently a caption in the
                                .caption file.
 --css_dir=DIRECTORY          # Directory location of css files.  Default is
                                /usr/local/image_gallery/test/css
 --debug                      # Enable debugging
 --dir=DIRECTORY              # Directory to read the .caption in and write the
                                html out to.
 --existence                  # If a file is not present in the directory do not
                                process the associated .caption entry
 --favicon=FILE               # Specify a location to a favicon.
 --format=IMAGE_TYPE          # Type of image to create.  Default is same as
                                original image.
 -h|--help                    # Commandline usage
 --norecursive                # Turn off recursive directory following.
 --percentage=PERCENT         # Percent to scale to.  --percentage and --width
                                are mutually exclusive.  Default is 150 pixels.
 --prepend=STRING             # What to prepend each image with.  Default is
                                .thumb_
 --quality=PERCENT            # Quality level for jpg output.  Default is 75%.
 --recursive                  # Follow subdirectories under --dir.  On by
                                default.
 --template_dir=DIRECTORY     # Directory location of template files.  Default
                                is /usr/local/image_gallery/test/templates
 --template_debug             # Enable Template toolkit debugging.
 --thumbs                     # Create thumbnails
 --width                      # Width in pixels to scale thumbnails to.
                                Default is 150.

END

 exit 0;
}
