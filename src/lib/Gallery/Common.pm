package Image::Gallery::Common;
################################################################################
# $Id: Common.pm,v 1.10 2007-06-19 05:52:01 dleonard Exp $
# $Date: 2007-06-19 05:52:01 $
#
# Common Image::Gallery methods
# 
#  Licensed under GPL v2
#  (c) 2005-2026 dleonard@dleonard.net
################################################################################
use strict;
use warnings;

use Digest::MD5;
use File::Path qw(make_path);
use Sys::Syslog;

# Per-directory source-image checksum cache, so scaling can be skipped when a
# source is unchanged. coreutils md5sum format, so `md5sum -c` reads it too.
use constant MD5SUMS => '.md5sums';

my @validlevels = ('alert',
                   'crit',
                   'debug',
                   'emerg',
                   'err',
                   'info',
                   'notice',
                   'warning');

my $facility = 'local0';
my $logfile = '';
my $logger = '';
my $nolog = 0;
my $quiet = 0;

################################################################################
# debug
################################################################################
sub debug {
 my ($self, $level) = splice(@_, 0, 2);

 # Assume that the debug level is being set or requested
 if (!scalar @_) {
  if (defined $level && $level !~ /\D/) {
   $self->{_DEBUG} = $level;
   return $self->{_DEBUG};
  } elsif (!defined $level) {
   return $self->{_DEBUG};
  }
 }

 my $caller = (caller(1))[3];

 # No level passed in, assume if debug is true it should be printed
 if ($level =~ /\D/) {
  print "$level @_\n" if $self->{_DEBUG};

 # See if level is matched or exceeded by current debug level
 } elsif ($level <= $self->{_DEBUG}) {
  print "@_\n";
 }
} #debug

################################################################################
# error
################################################################################
sub error {
 my $self = shift;

 # If a logfile is specified write to it.  Otherwise write to STDERR.
 my $fh;
 if ($logfile) {
  open ($fh, '>>', $logfile);
 } else {
  open ($fh, '>&', \*STDERR);
 }

 my $date = localtime(time);

 foreach (@_) {
  print $fh "$date: $_\n";
 }

 close $fh;
} #error

################################################################################
# facility
################################################################################
sub facility {
 my $self = shift;
 # Set $facility if something got passed in.
 $facility = shift if scalar @_;

 return $facility;
} #facility

################################################################################
# fatal
################################################################################
# Log the error, then throw. Callers (or an uncaught die) report it; this used
# to exit(1) directly, which a library must not do.
sub fatal {
 my $self = shift;

 $self->logger('err', @_);

 die @_ ? join("\n", @_) . "\n" : "Fatal error.\n";
} #fatal

################################################################################
# logfile
################################################################################
sub logfile {
 my $self = shift;
 # Specify an output file to use rather than STDERR for errors.
 if (scalar @_) {
  $logfile = shift;
 }

 return $logfile;
} #logfile

###################################################################
# logger
###################################################################
sub logger {
 my $self = shift;

 return if $nolog;

 my @message = @_;
 return if !scalar @message;
 
 # Set the syslog level (default to info if none specified)
 my ($level) = grep {$_ eq $message[0]} @validlevels;
 if ($level) {
  shift @message;
 } else {
  $level = 'info';
 }

 my $previouscaller = (caller(2))[1];
 my $caller = (caller(1))[3];

 if ($logger) {
  my $loggercmd = $self->{loggercmd} || $logger;
  system($loggercmd, '-p', "$facility.$level", "$previouscaller $caller: @_");

 } else {
  openlog($0, 'pid', $facility);

  # Make each message a separate syslog event
  foreach my $i (@message) {
   syslog($level, "$previouscaller $caller: $i");
  }
 }
} #logger

################################################################################
# nolog
#  A false value passed in to nolog reenables logging.
#  Any other call disables logging.
################################################################################
sub nolog {
 my ($self, $level) = @_;

 if (defined $level && !$level) {
  $nolog = 0;
 } else {
  $nolog = 1;
 }
}

################################################################################
# mute
################################################################################
sub mute {
 my $self = shift;

 # Store prior values
 $self->{_history}{nolog} = $nolog;
 $self->{_history}{quiet} = $quiet;
 
 # Turn off logging
 $nolog = 1;

 # Quiet output
 $quiet = 1;
}

################################################################################
# quiet
################################################################################
sub quiet {
 my $self = shift;
 # Turn on/off quiet flag if something was passed in.
 $quiet = shift if scalar @_;

 # Return the current quiet value
 return $quiet;
} #quiet

################################################################################
# unmute
################################################################################
sub unmute {
 my $self = shift;

 # Restore from history
 $nolog = $self->{_history}{nolog};
 $quiet = $self->{_history}{quiet};
}

################################################################################
# current_date
################################################################################
sub current_date {
 my $self = shift;

 my @date = localtime(time);
 $date[5] += 1900;
 $date[4]++;

 return sprintf '%4d-%.2d-%.2d %.2d:%.2d:%.2d', @date[5,4,3,2,1,0];
} #current_date

################################################################################
# date
################################################################################
sub date {
 my $self = shift;

 if (scalar @_) {
  $self->{date} = shift;
 } else {
  $self->{date} = $self->current_date();
 }

 return $self->{date};
}

################################################################################
# Calculate md5 checksum
# I: $file
# O: $sum
################################################################################
sub md5 {
 my ($self, $file) = @_;

 my $fh;
 if (!open($fh, '<', $file)) {
  $self->fatal("Unable to open [$file] for md5sum.");
 }

 binmode($fh);

 my $sum = Digest::MD5->new->addfile($fh)->hexdigest;
 close $fh;
 return $sum;
}

################################################################################
# readMd5sums
#  Read a directory's .md5sums cache.
# I: $dir
# O: \%sums                  # basename => md5 hex (empty if no cache yet)
################################################################################
sub readMd5sums {
 my ($self, $dir) = @_;

 my $file = $dir . '/' . MD5SUMS;
 my %sums;
 return \%sums if !-f $file;

 my $fh;
 if (!open($fh, '<', $file)) {
  $self->fatal("Unable to open [$file] for reading.");
 }

 # Each line is "<hex>  <name>" or "<hex> *<name>" (text/binary marker).
 while (my $line = <$fh>) {
  if (my ($sum, $name) = $line =~ /^([0-9a-fA-F]{32}) [ *](.+?)\s*$/) {
   $sums{$name} = lc $sum;
  }
 }
 close $fh;

 return \%sums;
}

################################################################################
# writeMd5sums
#  Write a directory's .md5sums cache.
# I: $dir
#    \%sums                  # basename => md5 hex
################################################################################
sub writeMd5sums {
 my ($self, $dir, $sums) = @_;

 my $file = $dir . '/' . MD5SUMS;

 my $fh;
 if (!open($fh, '>', $file)) {
  $self->fatal("Unable to open [$file] for writing.");
 }

 foreach my $name (sort keys %$sums) {
  print $fh "$sums->{$name}  $name\n";
 }
 close $fh;
}

################################################################################
# getSubdirectories
# I: $dir       # Directory path
# O: $dirs      # Reference to list of directories
#    $full_dirs # Reference to list of directories full path
################################################################################
sub getSubdirectories {
 my ($self, $dir, $options) = @_;
 if (!ref $options) {
  splice(@_, 0, 2);
  $options = scalar @_ ? {@_} : {};
 }

 # Get the subdirectories
 my $dh;
 if (!opendir ($dh, $dir)) {
  $self->fatal("Unable to open directory [$dir].");
 }
 my @dirs = grep {-d $dir . '/' . $_ && !/^\.+/} readdir($dh);
 closedir $dh;

 my @full_dirs = map {$dir . '/' . $_} @dirs;

 return (\@dirs, \@full_dirs);
}

################################################################################
# getFiles
# I: $dir       # Directory path
# O: $dirs      # Reference to list of files
#    $full_dirs # Reference to list of files full path
################################################################################
sub getFiles {
 my ($self, $dir, $options) = @_;
 if (!ref $options) {
  splice(@_, 0, 2);
  $options = scalar @_ ? {@_} : {};
 }

 # Get the files
 my $dh;
 if (!opendir ($dh, $dir)) {
  $self->fatal("Unable to open directory [$dir].");
 }
 my @files = grep {-f $dir . '/' . $_ && !/^\.+/} readdir($dh);
 closedir $dh;

 my @full_files = map {$dir . '/' . $_} @files;

 return (\@files, \@full_files);
}

################################################################################
# mkdir
# I: $dir
#    $perms                   # In octal
#    $options->{nonfatal}     # Default behavior is fatal on error
# O: Boolean                  # True = success
################################################################################
sub mkdir {
 my ($self, $dir, $perms, $options) = @_;
 if (!ref $options) {
  splice(@_, 0, 3);
  $options = scalar @_ ? {@_} : {};
 }

 $perms ||= $self->{perms} || 0775;

 if (!-d $dir) {
  make_path($dir, {mode => $perms, error => \my $errors});
  if (!-d $dir) {
   unless ($options->{nonfatal}) {
    $self->fatal("Unable to read or create directory [$dir].");
   }

   return 0;
  }
 }

 return 1;
}

1;
