#!/usr/bin/perl
################################################################################
# Functional test wrapper for Image::Gallery.
#
# Checks that the required modules are installed, then exercises caption
# parsing, thumbnail and web-size generation, and HTML output against the
# sample data in this directory.  Run directly or via `make test`.
################################################################################
use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use File::Temp qw(tempdir);
use File::Copy qw(copy);

# Non-core modules the tests need, with the package names to install them.
my @deps = (
 {module => 'Image::Magick', deb => 'perlmagick',       rpm => 'ImageMagick-perl',      cpan => 'Image::Magick'},
 {module => 'Template',      deb => 'libtemplate-perl',  rpm => 'perl-Template-Toolkit', cpan => 'Template'},
);

# Check dependencies before loading the gallery modules, so a missing one gives
# clear install instructions instead of a bare "Can't locate ... in @INC".
my @missing = grep { my $m = $_->{module}; !eval "require $m; 1" } @deps;
if (@missing) {
 print STDERR "Cannot run tests: required Perl module(s) not installed.\n\n";
 for my $d (@missing) {
  print STDERR "  $d->{module}\n";
  print STDERR "    Debian/Ubuntu:     sudo apt install $d->{deb}\n";
  print STDERR "    RHEL/Amazon Linux: sudo dnf install $d->{rpm}\n";
  print STDERR "    CPAN:              cpan $d->{cpan}\n\n";
 }
 exit 1;
}

# The source tree keeps Image::Gallery::* under src/lib as Gallery.pm etc; Perl
# expects them beneath Image/, so stage a symlink Image -> src/lib and use that.
my $srclib = File::Spec->rel2abs(
             File::Spec->catdir($Bin, File::Spec->updir(), 'src', 'lib'));
my $stage  = tempdir(CLEANUP => 1);
symlink($srclib, File::Spec->catdir($stage, 'Image'))
 or die "Unable to stage modules from $srclib: $!\n";
unshift @INC, $stage;

use Test::More;

use_ok('Image::Gallery')          or BAIL_OUT('Image::Gallery failed to load');

# --- caption parsing -------------------------------------------------------
my $cap = Image::Gallery::Caption->new(dir => $Bin);
$cap->read();
is($cap->title('havok_w1.jpg'), 'Havok and Wolverine',
   'caption title parsed from .caption');
is($cap->medium('havok_w1.jpg'), 'Acrylic on paper',
   'caption medium parsed from .caption');

# --- thumbnail generation --------------------------------------------------
my $work = tempdir(CLEANUP => 1);
copy("$Bin/havok_w1.jpg", "$work/havok_w1.jpg") or die "copy: $!";

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

# --- HTML output -----------------------------------------------------------
my $htmldir = tempdir(CLEANUP => 1);
copy("$Bin/havok_w1.jpg", "$htmldir/havok_w1.jpg") or die "copy: $!";
copy("$Bin/.caption",     "$htmldir/.caption")     or die "copy: $!";

my $gallery = Image::Gallery->new(dir          => $htmldir,
                                  template_dir => "$Bin/templates");
$gallery->captions({existence => 1});
$gallery->html();

my $index = "$htmldir/index.html";
ok(-f $index, 'index.html generated');
open(my $fh, '<', $index) or die "open $index: $!";
my $html = do { local $/; <$fh> };
close $fh;
like($html, qr/havok_w1\.jpg/,       'html references the image');
like($html, qr/Havok and Wolverine/, 'html includes the caption title');

done_testing();
