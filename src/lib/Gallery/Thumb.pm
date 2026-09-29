package Image::Gallery::Thumb;
################################################################################
# $Id: Thumb.pm,v 1.21 2012-09-25 15:15:38 dleonard Exp $
# $Date: 2012-09-25 15:15:38 $
#
# Thumbnail generating library for Image::Gallery
#
#  Licensed under GPL v2
#  (c) 2004-2026 Douglas Leonard
################################################################################
use strict;
use warnings;

use Image::Magick;
use Exporter;

use Image::Gallery::Common;
use parent -norequire, 'Exporter', 'Image::Gallery::Common';

our (@EXPORT_OK, %EXPORT_TAGS);

use constant PREPEND => '.thumb_';
use constant POSTPEND => '_thumb';

@EXPORT_OK = qw(PREPEND POSTPEND);
%EXPORT_TAGS = (all => \@EXPORT_OK);

my %default = (width => 150,
               quality => 75);

################################################################################
# new
# I: $options->{Image}    # Image::Magick object
#              {image}    # Path to source image
#              {postpend} # What to postpend to the filename
#              {prepend}  # What to prepend to the filename
################################################################################
sub new {
 my ($class, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $self = {Image => undef,
             image => undef,
             postpend => undef,
             prepend => &PREPEND};

 foreach (keys %$self) {
  $self->{$_} = $options->{$_} if exists $options->{$_};
 }

 # Create Image if it wasn't passed in
 if (!$self->{Image}) {
  $self->{Image} = Image::Magick->new();
  $class->fatal('Unable to create new Image::Magick object.') if !$self->{Image};
 }

 my $err = $self->{Image}->Read($self->{image} . '[0]');
 $class->fatal($err) if $err;

 # Get a few attributes needed in a number of places
 ($self->{width}, $self->{height}, $self->{size}, $self->{format}) = $self->{Image}->Ping($self->{image});

 return bless $self, $class;
}

################################################################################
# scale
#  Resize the image
# I: $options->{percentage} # Integer percentage
#              {width}      # Width in pixels
################################################################################
sub scale {
 my ($self, $options) = @_;
 if (!ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $width = defined $options->{width} ? $options->{width} : $default{width};

 if ($options->{percentage}) {
  $width = $self->{width} * $options->{percentage} / 100;
 }

 my $height = int($width / $self->{width} * $self->{height});

 my $err = $self->{Image}->Scale(width => $width,
                                 height => $height);
 $self->fatal($err) if $err;
}

################################################################################
# write
# I: $options->{format}      # Valid image extension
#              {overwrite}   # Overwrite if already present
#              {quality}     # 0..100
################################################################################
sub write {
 my ($self, $options) = @_;
 if (!ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 $self->{thumb} ||= $self->generateThumbFilename($options);

 # Don't bother rewriting the file if it already exists unless overwrite is
 # specified
 if (-f $self->{thumb}) {
  return $self->{thumb} if !$options->{overwrite};
 }

 # Quality is 0 to 100 for jpeg (0 is worst)
 my $quality = defined $options->{quality} ? $options->{quality} : $default{quality};
 my $return =  $self->{Image}->Write(filename => $self->{thumb},
                                     quality => $quality);

 $self->fatal($return) if $return;

 # Somehow imagemagick fails to write out the file sometimes without an error.
 # Catch that case.
 if (!-f $self->{thumb}) {
  $self->error("File [$self->{thumb}] was not written out.");
 }
}

################################################################################
# generateThumbFilename
# $options->{format}
################################################################################
sub generateThumbFilename {
 my ($self, $options) = @_;
 if (!ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 # Callable on an object or as a class method with image/prepend/postpend
 # passed in, so a filename can be derived without reading the image.
 my $image    = defined $options->{image}    ? $options->{image}    : (ref $self ? $self->{image}    : undef);
 my $prepend  = exists  $options->{prepend}  ? $options->{prepend}  : (ref $self ? $self->{prepend}  : undef);
 my $postpend = exists  $options->{postpend} ? $options->{postpend} : (ref $self ? $self->{postpend} : undef);

 my $thumb;
 ($thumb = $image) =~ s#([^/]+)\.([^/]+)$##;
 $thumb .= $prepend if $prepend;
 $thumb .= $1;
 $thumb .= $postpend if $postpend;
 if ($options->{format}) {
  $thumb .= '.' . $options->{format};
 } else {
  $thumb .= '.' . $2;
 }

 return $thumb;
}

sub DESTROY {}

1;

__END__

=head1 NAME

Image::Gallery::Thumb - Web image gallery thumbnail generator

=head1 SYNOPSIS

 use Image::Gallery::Thumb

=head1 ABSTRACT

This module provides functionality to create thumbnail files for images in a specified directory.

=head1 DESCRIPTION

This module provides the ability to create thumbnails of specified size, type, and detail level for images in a specified directory.  Additionally it can recurse through a directory structure creating thumbnails at each level.  This module is commonly included by Image::Gallery.pm but can be used stand-alone.

=head1 METHODS
