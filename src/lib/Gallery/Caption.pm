package Image::Gallery::Caption;
################################################################################
# $Id: Caption.pm,v 1.36 2012-09-25 15:15:38 dleonard Exp $
# $Date: 2012-09-25 15:15:38 $
#
# Caption handling library for Image::Gallery
################################################################################
use strict;
use warnings;

use File::Copy;

use Image::Gallery::Common;
use parent -norequire, 'Image::Gallery::Common';

# List valid fields and the order in which they should appear
@Image::Gallery::Caption::Fields = ('dir',
                                    'file',
                                    'artist',
                                    'comment',
                                    'copyright',
                                    'date',
                                    'date_captured',
                                    'height',
                                    'medium',
                                    'sequence',
                                    'size',
                                    'title',
                                    'width');

# Set defaults
%Image::Gallery::Caption::Fields = map {$_ => undef} @Image::Gallery::Caption::Fields;

# Mapping between valid fields and equivalent Exif fields
%Image::Gallery::Caption::Exif = (artist => 'Artist',
                                  comment => 'UserComment',
                                  copyright => 'Copyright',
                                  date => 'DateTimeOriginal',
                                  date_captured => 'DateTimeDigitized',
                                  height => 'ImageWidth',
                                  title => 'ImageDescription',
                                  width => 'ImageLength');

%Image::Gallery::Caption::Description = (file => 'Filename.  Can include path',
                                         dir => 'Subdirectory.  Can include path',
                                         artist => 'Artist',
                                         comment => 'Long description or comment',
                                         copyright => 'Copyright',
                                         date => 'Date image created',
                                         date_captured => 'Date image digitized',
                                         height => 'Image height (pixels)',
                                         medium => 'Original artwork medium',
                                         sequence => 'Display order',
                                         size => 'Original artwork size',
                                         title => 'Image title or short description',
                                         width => 'Image width (pixels)');

################################################################################
# Auto-generate accessor and assignment methods for each Field
# I: $file, [$value]
# O: value of $field for $file
################################################################################
foreach my $field (@Image::Gallery::Caption::Fields) {
 eval <<END;
sub $field {
 my (\$self, \$file) = splice (\@_, 0, 2);

 if (scalar \@_) {
  \$self->{captions}{\$file}{$field} = shift;
 }

 return \$self->{captions}{\$file}{$field};
}
END

}

################################################################################
# new
################################################################################
sub new {
 my ($class, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $self = {allfiles => 0,
             backup => undef,
             dir => '',
             existence => 0,
             file => ''};

 foreach (keys %$self) {
  $self->{$_} = $options->{$_} if exists $options->{$_};
 }

 if (!$self->{dir} && !$self->{file}) {
  $class->fatal('Must specify dir or file parameter.');
 }

 if (!$self->{dir}) {
  ($self->{dir} = $self->{file}) =~ s#[^/]+$##;
 } elsif (!$self->{file}) {
  $self->{file} = $self->{dir} . '/.caption';
 }

 return bless $self, $class;
} #new

################################################################################
# read
# I: $options->{allfiles}
#              {existence}
################################################################################
sub read {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $allfiles = $options->{allfiles} || $self->{allfiles};
 
 if (!-f $self->{file} && !$allfiles) {
  $self->fatal('No caption file defined and allfiles option not set.');
 }
 my $fh;
 if (!open($fh, '<', $self->{file}) && !$allfiles) {
  $self->fatal('Unable to read caption file [' . $self->{file} . '].');
 }

 $self->{captions} = {};
 $self->{dir_captions} = {};

 if ($self->{allfiles} || $options->{allfiles}) {
  $self->files();
 }

 my $new = '';
 while ($fh && (my $line = <$fh>)) {
  next if $line =~ /^\s*$/; # Skip blank lines
  next if $line =~ /^\s*#/; # Skip commented lines

  $line =~ m/^\s*([^=]+?)\s*=\s*(["']*)(.*)\s*$/;
  my $key = $1;
  my $value = $3;

  # Strip enclosing ' or " from $value if necessary
  $value =~ s/\Q$2\E$//;

  # Skip keys that aren't in the valid list
  next if !exists $Image::Gallery::Caption::Fields{$key};
  # Skip keys that don't have a value defined
  next if (!$value && $value != 0);

  if ($key eq 'file') {
   $new = $value;
   $self->{captions}{$new} = {};
  } elsif ($key eq 'dir') {
   $new = $value;
   $self->{dir_captions}{$new} = {};
  }

  # Note that this results in a file parameter for the file hash also.
  $self->{captions}{$new}{$key} = $value;
 }

 close $fh if $fh;

 # Strip entries that don't exist on the filesystem
 if ($self->{existence} || $options->{existence}) { 
  foreach my $key (keys %{$self->{captions}}) {
   if ($self->{files} && !$self->{files}{$key}) {
    delete $self->{captions}{$key};
   } else {
    my $tmpname =  $self->{dir} . '/' . $key;
    if (!-d $tmpname && !-f $tmpname) {
     delete $self->{captions}{$key};
    }
   }
  }
 }
}

################################################################################
# printCaptions
# I: $format             # printf format
#    $options->{dirs}    # list print dir_captions
#
# Outputs caption data to STDOUT
################################################################################
sub listCaptions {
 my ($self, $format, $options) = @_; 
 $options = {} if !ref $options;
 $format ||= "%s: %s\n";

 my $hashref = $options->{dirs} ? $self->{dir_captions} : $self->{captions};

 foreach my $file (sort {$self->captionSort()} keys %$hashref) {
  printf $format, 'file', $file;

  foreach my $elem (@Image::Gallery::Caption::Fields[1..$#Image::Gallery::Caption::Fields]) {
   printf $format, ' ' . $elem, $hashref->{$file}{$elem} // '';
  }
 }
}

################################################################################
# write
# I: $options->{backup}
#
# TODO add dir_captions support
################################################################################
sub write {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 if ($self->{backup} || $options->{backup}) {
  copy($self->{file}, $self->{file} . '.bak');
 }

 my $fh;
 if (!open ($fh, '>', $self->{file})) {
  $self->fatal('Could not open [' . $self->{file} . '] for writing.');
 }

 foreach my $file (sort {$self->captionSort()} keys %{$self->{captions}}) {
  printf $fh "file: %s\n", $file;

  foreach my $elem (@Image::Gallery::Caption::Fields[1..$#Image::Gallery::Caption::Fields]) {
   printf $fh " %s: %s\n", $elem, $self->{captions}{$file}{$elem} // '';
  }
  print $fh "\n";
 }

 close $fh;
} #write

################################################################################
# files
#  Get list of files in 'dir'
#
# TODO update to use getFiles() and getSubdirectories()
################################################################################
sub files {
 my ($self) = @_;

 my $dh;
 if (!opendir($dh, $self->{dir})) {
  $self->fatal("Unable to open directory [$self->{dir}].");
 }

 # TODO turn this into a loop and track the directories too.
 my @dirs = ();

 my @files = grep {-f $_} map {$self->{dir} . '/' . $_ } grep {!/^\.|CVS|.*html/} readdir($dh);
 closedir $dh;

 $self->{files} = {};
 foreach my $file (@files) {
  $file =~ s#.*?([^/]+)$#$1#;
  $self->{files}{$file} = 1;
  $self->{captions}{$file} = {};
 }

} #files

################################################################################
# captionSort
#
# Sort method.  Sort first by sequence, then alphabetically.  Entries with
# sequence take precedence over entries without.
################################################################################
sub captionSort {
 my $self = shift @_;

 if (defined $self->{captions}{$a}{sequence}) {
  if (defined $self->{captions}{$b}{sequence}) {
   return $self->{captions}{$a}{sequence} <=> $self->{captions}{$b}{sequence};
  }
  return -1;
 } elsif (defined $self->{captions}{$b}{sequence}) {
  return 1;
 }

 return $a cmp $b;
}
 
1;

__END__

=head1 NAME

Image::Gallery::Caption - Web image gallery captions

=head1 SYNOPSIS

 use Image::Gallery::Caption

=head1 ABSTRACT

This module provides methods for reading and writing Image::Gallery .caption files.

=head1 DESCRIPTION

This module provides read and write methods for parsing and generating Image::Gallery .caption files.  See caption_file_spec.txt included with image_gallery for the details regarding the format and specification of a .caption file.  This module is commonly included by Image::Gallery.pm but can be used stand-alone.

=head1 METHODS

=head2 new(\%config)

The new() constructor method instantiates a new Image::Gallery::Caption object.  A reference to a hash of configuration items may be passed as a parameter.

 my $caption = Image::Gallery::Caption->new({allfiles => 0,
                                             backup => undef,
                                             dir => '',
                                             existence => 0,
                                             file => ''});

For convenience configuration items may also be specified as a hash of items rather than as a hash reference.

  my $caption = Image::Gallery::Caption->new(allfiles => 1,
                                             dir => '/usr/local/image_gallery/test/images'
                                             existence => 1);

If option I<allfiles> is passed in with a true value, then I<dir> is scanned to find all files in that directory.  A minimal caption for each file will be created even if the file isn't present in the .caption file.  By default I<allfiles> is turned off.

I<backup> forces the backing up of I<file> as I<file>.bak before a new file is written out.  By default I<backup> is turned off.

If option I<dir> is passed in, it is the directory where the gallery is.  If option I<dir> is not passed in, then it is derived from I<file>.  Either I<file> or I<dir> is required.

I<existence> forces a file to be present on the filesystem for it to have a caption.  If a file entry in .caption doesn't correspond to a filesystem entry then it will not be used.  By default I<existence> is turned off.

If option I<file> is passed in, the captions will be read from or written to the specified I<file>.  If option I<file> is not passed in, it is assumed that I<file> is a .caption file in I<dir>.

=head2 read(\%options)

The read() method parses a .caption file, reading in a caption for each file entry.  Additionally if I<allfiles> or $options->{allfiles} is set to true then a caption entry is created for each file in I<dir>.  If I<existence> or $options->{existence} is set to true then files that don't exist on the filesystem will not have caption entries.

=head2 listCaptions($format)

The listCaptions() method prints to STDOUT a listing of caption entries as read in by C<read()>.  It accepts C<$format> as an input variable which is a printf formatting string.

=head2 write(\%options)

The write() method writes out a .caption to I<file>.  If I<backup> or $options->{backup} is set to a true value then a backup of the pre-existing .caption file is written as .caption.bak.

=head2 files()

The files() method reads in all files from I<dir> excepting filenames beginning with ., containing CVS, or html.  For each file read in a rudimentary caption is created within the object.  This is useful as an optimization in conjunction with C<$caption-E<gt>read({allfiles =E<gt> 1})>.

=head2 captionSort()

Sort two files based primarily upon the sequence specified for them in the object.  If only one file has a sequence that file has precedence.  If neither file has a sequence, sort alphabetically.

=over

=back

=head1 AUTHOR

Douglas Leonard, E<lt>dleonard@dleonard.netE<gt>

L<https://github.com/dleonard04/image-gallery>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2026 by Douglas Leonard

This library is free software; you can redistribute it and/or modify it under the terms of the General Public License (GPL) version 2.  For more information, see http://www.fsf.org/licenses/gpl.txt

=cut
