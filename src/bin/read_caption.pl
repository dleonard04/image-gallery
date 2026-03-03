#!/usr/bin/perl
################################################################################
# Photo caption reading script.  Part of the Image::Gallery suite.
#
# (c) 2006 dleonard@dleonard.net
################################################################################
use strict;

use Getopt::Long;
Getopt::Long::Configure('bundling');

use Image::Gallery;

my $help = undef;
my %options = (dir => '/usr/local/image_gallery/test/images',
               recursive => 1);
GetOptions(\%options,
           'allfiles',
           'dir=s',
           'existence',
           'h|help' => \$help,
           'recursive');

help() if $help;
           
my $gallery = Image::Gallery->new(\%options);
$gallery->captions();

# Print individual attribute for individual file.
print $gallery->{Caption}{$options{dir}}->title('havok_w1.jpg') . "\n";

# Dump all captions
$gallery->listCaptions();

################################################################################
# help
################################################################################
sub help {
 print <<END;
read_caption.pl
 --allfiles                   # Create a caption for all files in the directory
                                even if there isn't currently a caption in the
                                .caption file.
 --dir=DIRECTORY              # Directory to read the .caption in
 --existence                  # If a file is not present in the directory do not
                                process the associated .caption entry
 -h|--help                    # Commandline usage
 --recursive                  # Follow subdirectories reading .caption files in
                                each.

END

 exit 0;
}

