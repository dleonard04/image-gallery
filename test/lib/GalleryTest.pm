package GalleryTest;
################################################################################
# Shared setup and helpers for the Image::Gallery functional tests in t/.
#
# Loading this module stages the source tree so Image::Gallery::* resolve, and
# adds the staging directory to @INC -- so a test can `use GalleryTest` and then
# `use Image::Gallery` and have it found, whether run under run_tests.pl or on
# its own with `prove t/NN-name.t`.
################################################################################
use strict;
use warnings;

use File::Spec;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Exporter 'import';

our @EXPORT_OK = qw(sample_dir spew slurp);

# The source tree keeps Image::Gallery::* under src/lib as Gallery.pm etc; Perl
# expects them beneath Image/, so paths are resolved from this file's location.
my $lib_dir = dirname(File::Spec->rel2abs(__FILE__));
my $sample  = File::Spec->rel2abs(File::Spec->catdir($lib_dir, File::Spec->updir()));
my $src_lib = File::Spec->rel2abs(
              File::Spec->catdir($lib_dir, File::Spec->updir(), File::Spec->updir(),
                                 'src', 'lib'));

# Non-core modules the tests need, with the package names to install them.
our @DEPS = (
 {module => 'Image::Magick', deb => 'perlmagick',      rpm => 'ImageMagick-perl',      cpan => 'Image::Magick'},
 {module => 'Template',      deb => 'libtemplate-perl', rpm => 'perl-Template-Toolkit', cpan => 'Template'},
);

# Stage Image -> src/lib and put it on @INC. Kept in a package global so the
# temp directory survives for the life of the process.
our $STAGE = tempdir(CLEANUP => 1);
symlink($src_lib, File::Spec->catdir($STAGE, 'Image'))
 or die "Unable to stage modules from $src_lib: $!\n";
unshift @INC, $STAGE;

# Directory holding the sample images, .caption files, and templates.
sub sample_dir { return $sample }

# Modules from @DEPS that are not installed.
sub missing_deps {
 return grep { my $m = $_->{module}; !eval "require $m; 1" } @DEPS;
}

# Write $content to $file (used to mark a thumb so a rewrite is detectable).
sub spew {
 my ($file, $content) = @_;
 open(my $out, '>', $file) or die "open $file: $!";
 print $out $content;
 close $out;
}

# Return the entire contents of $file.
sub slurp {
 my ($file) = @_;
 open(my $in, '<', $file) or die "open $file: $!";
 my $content = do { local $/; <$in> };
 close $in;
 return $content;
}

1;
