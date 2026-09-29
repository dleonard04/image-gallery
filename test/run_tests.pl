#!/usr/bin/perl
################################################################################
# Functional test runner for Image::Gallery.
#
# Checks that the required modules are installed, then runs every test in t/
# (caption parsing, thumbnail and web-size generation, incremental .md5sums
# regeneration, and HTML output) against the sample data in this directory.
# Run directly or via `make test`. Individual files also run under
# `prove t/NN-name.t`; shared setup lives in lib/GalleryTest.pm.
################################################################################
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use GalleryTest;

use TAP::Harness;

# Check dependencies once, up front, so a missing one gives clear install
# instructions instead of a bare "Can't locate ... in @INC" from every file.
my @missing = GalleryTest::missing_deps();
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

my @tests = sort glob "$FindBin::Bin/t/*.t";
my $harness = TAP::Harness->new({lib => ["$FindBin::Bin/lib"]});
my $agg = $harness->runtests(@tests);

exit($agg->has_errors ? 1 : 0);
