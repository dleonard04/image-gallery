package Image::Gallery;
################################################################################
# $Id: Gallery.pm,v 1.51 2012-09-25 15:14:43 dleonard Exp $
# $Date: 2012-09-25 15:14:43 $
#
# Image Gallery generation software
################################################################################
use strict;
use warnings;

use Image::Gallery::Common;
use parent -norequire, 'Image::Gallery::Common';

use Image::Gallery::Caption;
use Image::Gallery::Html;
use Image::Gallery::Thumb ':all';

################################################################################
# new
# I: $options->{dir}
#              {file}
#              {recursive}
#              {template_dir}
#              {debug}
################################################################################
sub new {
 my ($class, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $self = {dir => undef,
             file => undef,
             recursive => undef,
             template_dir => undef,
             debug => undef};

 foreach (keys %$self) {
  $self->{$_} = $options->{$_} if exists $options->{$_};
 }

 if (!$self->{dir} && !$self->{file}) {
  $class->fatal('Need to specify a directory or a file to generate a gallery.');
 }

 # Initialize other attributes
 $self->{Caption} = {}; # Caption object per directory
 $self->{dirTree} = {}; # Hash keyed on dir whose values are arrays of dirs

 return bless $self, $class;
} #new

################################################################################
# files
#  Get list of files to shove into the 'files' element.
# I: $options->{dir}
#              {noassign} # Don't modify $self->{files}
#              {ignore}   # Array of patterns to ignore
################################################################################
sub files {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $tmplist = [];

 if ($self->{file}) {
  $tmplist = [$self->{file}];

 } else {
  my $dir = $options->{dir} || $self->{dir};

  my $dh;
  if (!opendir($dh, $dir)) {
   $self->fatal("Unable to open directory [$dir].");
  }

  $tmplist = [map {$dir . '/' . $_} grep {!/^\.|CVS/} readdir($dh)];
  closedir $dh;

  if ($self->{recursive} && !$options->{noassign}) {
   $self->_recursive($tmplist);
  } else {
   @$tmplist = grep {-f $_} @$tmplist;
  }

 }

 if ($options->{ignore} && ref $options->{ignore}) {
  foreach my $ignore (@{$options->{ignore}}) {
   @$tmplist = grep {!/$ignore/} @$tmplist;
  }
 }

 unless ($options->{noassign}) {
  @{$self->{files}} = @$tmplist;
 }

 return $tmplist;
} #files

################################################################################
# dirs
#  Get list of directories to shove into the dirs element.
################################################################################
sub dirs {
 my $self = shift;

 if (!$self->{dir} || !-d $self->{dir}) {
  return;
 }

 $self->{dirs} = [$self->{dir}];

 if ($self->{recursive}) {
  $self->_recursive_dirs();
 }

 return $self->{dirs};
} #dirs

################################################################################
# thumbs
#  Write out all thumbnail files
# I: $options->{format}
#              {ignore}
#              {overwrite}
#              {percentage} || {width}
#              {postpend}
#              {prepend}
#              {quality}
################################################################################
sub thumbs {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 # Don't attempt to scale html files
 my @ignore = ('.html*$');

 # Ignore already scaled images of the type passed in or of the default opposite
 # type (post/pre)
 if ($options->{postpend}) {
  push @ignore, '^' . &Image::Gallery::Thumb::PREPEND;
  push @ignore, "$options->{postpend}\\.[^\\.]+\$";
 } else {
  $options->{prepend} ||= &Image::Gallery::Thumb::PREPEND;
  push @ignore, "^$options->{prepend}";
  push @ignore, &Image::Gallery::Thumb::POSTPEND . '\.[^\.]+$';
 }

 # Extra things to ignore may get passed in
 if ($options->{ignore}) {
  if (ref $options->{ignore} eq 'ARRAY') {
   push @ignore, @{$options->{ignore}};
  } else {
   push @ignore, $options->{ignore};
  }
 }

 $self->files({ignore => \@ignore});

 my %thumb_options = ();
 foreach my $pend ('prepend', 'postpend') {
  $thumb_options{$pend} = $options->{$pend};
 }
 my %scale_options = ();
 if ($options->{width}) {
  $scale_options{width} = $options->{width};
 } elsif ($options->{percentage}) {
  $scale_options{percentage} = $options->{percentage};
 }

 my %write_options = ();
 foreach my $param ('format', 'overwrite', 'quality') {
  $write_options{$param} = $options->{$param} if defined $options->{$param};
 }

 # Regenerate everything, ignoring the .md5sums cache, when forced.
 my $force = $options->{force} || $options->{overwrite};

 my %md5cache; # dir => {basename => md5}
 my %dirty;    # dirs whose .md5sums need rewriting

 foreach my $file (@{$self->{files}}) {
  my ($dir, $base) = $file =~ m#^(.*)/([^/]+)$# ? ($1, $2) : ('.', $file);

  $md5cache{$dir} ||= $self->readMd5sums($dir);
  my $sum = $self->md5($file);
  my $changed = !defined $md5cache{$dir}{$base}
                || $md5cache{$dir}{$base} ne $sum;

  # Where this source's scaled copy lands. The cache is keyed on the source,
  # so thumbs and websized share it; each still regenerates its own output
  # whenever that output is missing.
  my $thumbfile = Image::Gallery::Thumb->generateThumbFilename(
                   {image => $file,
                    prepend => $thumb_options{prepend},
                    postpend => $thumb_options{postpend},
                    format => $options->{format}});

  # Skip unchanged sources whose scaled copy already exists.
  unless (!$force && !$changed && -f $thumbfile) {
   $thumb_options{image} = $file;
   my $thumb = Image::Gallery::Thumb->new(\%thumb_options);

   $thumb->scale(\%scale_options);
   $thumb->write({%write_options,
                  overwrite => ($force || $changed) ? 1 : $write_options{overwrite}});
  }

  if ($changed) {
   $md5cache{$dir}{$base} = $sum;
   $dirty{$dir} = 1;
  }
 }

 foreach my $dir (keys %dirty) {
  $self->writeMd5sums($dir, $md5cache{$dir});
 }
}

################################################################################
# captions
# I: $options->{allfiles}
#              {existence}
#  Parse the caption files and populate a Caption object for each directory.
################################################################################
sub captions {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 $self->dirs();

 foreach my $dir (@{$self->{dirs}}) {
  $self->{Caption}{$dir} = Image::Gallery::Caption->new(dir => $dir,
                                                        allfiles => $options->{allfiles},
                                                        existence => $options->{existence});
  $self->{Caption}{$dir}->read();
 }
} #captions

################################################################################
# listCaptions
# I: $format           # printf output format
################################################################################
sub listCaptions {
 my ($self, $format) = @_;

 foreach my $dir (sort keys %{$self->{Caption}}) {
  $self->{Caption}{$dir}->listCaptions($format);
 }
}

################################################################################
# html
#  Generate and output the gallery webpages.
# I: $options->{template_dir}
#              {input}
################################################################################
sub html {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $input = {};

 if (!$self->{dirs}) {
  $self->dirs();
 }

 foreach my $dir (@{$self->{dirs}}) {
  # Initialize the data to pass in to the Html object
  %{$input} = %{$options->{input}} if defined $options->{input};

  if (defined $self->{Caption}{$dir}) {
   if (ref $self->{Caption}{$dir}{captions}) {
    foreach my $file (keys %{$self->{Caption}{$dir}{captions}}) {
     $input->{captions}{$file} = $self->{Caption}{$dir}{captions}{$file};
    }
   }
  }

  if (defined $self->{dirTree}{$dir} && scalar @{$self->{dirTree}{$dir}}) {
   $input->{subdirs} = $self->{dirTree}{$dir};
  }

  my %html_hash = (debug => $self->{debug},
                   dir => $dir,
                   input => $input,
                   template_dir => $options->{template_dir}
                                   || $self->{template_dir},
                   title => $dir);

  my $html = Image::Gallery::Html->new(\%html_hash);

  if (!$html->write_file()) {
   $self->fatal('Unable to output gallery html.');
  }
 }
} #html

################################################################################
# pagedHtml
#  Generate and output the gallery webpages.  Placing 'page' images per page.
# I: $options->{existence}
#              {input}
#              {page}           # Number of images per page.  Default: 20
#              {template_dir}
################################################################################
sub pagedHtml {
 my ($self, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 $options->{page} ||= 20;

 if (!$self->{dirs}) {
  $self->dirs();
 }

 foreach my $dir (@{$self->{dirs}}) {
  # Initialize the data to pass in to the Html object
  my $input = {};
  %{$input} = %{$options->{input}} if defined $options->{input};

  my %html_hash = (debug => $self->{debug},
                   dir => $dir,
                   template_dir => $options->{template_dir}
                                   || $self->{template_dir});

  my $html = Image::Gallery::Html->new(\%html_hash);

  my $image_count = 0;
  my $page_number = 1;

  if (defined $self->{Caption}{$dir}) {
   if (ref $self->{Caption}{$dir}{captions}) {
    my $image_sum = scalar keys %{$self->{Caption}{$dir}{captions}};
    foreach my $file (keys %{$self->{Caption}{$dir}{captions}}) {
     $image_count++;
     $input->{captions}{$file} = $self->{Caption}{$dir}{captions}{$file};

     if ($image_count % $options->{page} == 0
         || ($image_sum <= $options->{page} && $image_count == $image_sum))
     {
      my $file = $self->_determineFileName($page_number);
      $self->_determinePreviousPage($input, $page_number);
      $self->_determineNextPage($input, $page_number, $image_count, $image_sum);
      $input->{current_page} = $page_number;

      if (!$html->write_file($file, undef, $input)) {
       $self->fatal('Unable to output gallery html for dir [' . $dir . '].');
      }

      # Reset the input hash for the next page
      %{$input} = %{$options->{input}} if defined $options->{input};
      $page_number++;
     }
    }
   }
  }
 }
}

################################################################################
# _determineFileName
# I: $page
# O: Name of the file
################################################################################
sub _determineFileName {
 my ($self, $page) = @_;

 return 'index.html' if $page == 1;
 return sprintf("index%.2d.html", $page);
}

################################################################################
# _determinePreviousPage
# I: $input                           # ref to hash of input data
#    $page                            # Current page number
#
# Sets $input->{previous_page}
#              {previous_page_link}
################################################################################
sub _determinePreviousPage {
 my ($self, $input, $page) = @_;

 if ($page == 2) {
  $input->{previous_page} = 1;
  $input->{previous_page_link} = 'index.html';
 } elsif ($page > 2) {
  $input->{previous_page} = $page - 1;
  $input->{previous_page_link} = sprintf("index%.2d.html", $page - 1);
 }
}

################################################################################
# _determineNextPage
# I: $input                           # ref to hash of input data
#    $page                            # Current page number
#    $image_count                     # Current image number
#    $image_sum                       # Number of images in directory
#
# Sets $input->{next_page}
#              {next_page_link}
################################################################################
sub _determineNextPage {
 my ($self, $input, $page, $image_count, $image_sum) = @_;

 if ($image_count < $image_sum) {
  $input->{next_page} = $page + 1;
  $input->{next_page_link} = sprintf("index%.2d.html", $page + 1);
 }
}
 
################################################################################
# _recursive
#  Populates $tmplist with the complete tree of files and returns it
################################################################################
sub _recursive {
 my ($self, $files) = @_;

 my @tmplist = ();

 foreach my $file (@$files) {
  if (-f $file) {
   push @tmplist, $file;

  } elsif (-d $file) {
   my $dh;
   if (!opendir($dh, $file)) {
    $self->fatal("Unable to open directory [$file].");
   }

   # Append new things found in the directory to the end of our list of things
   # to iterate over.  Note: this could result in an infinite loop if following
   # symlinks was allowed.
   push @$files, map {$file . '/' . $_} grep {!/^\.|CVS/} readdir($dh);
   closedir($dh);
  }
 }

 @$files = @tmplist;
} #_recursive

################################################################################
# _recursive_dirs
#  Populates $self->{dirs} with all directories found under $self->{dirs}
################################################################################
sub _recursive_dirs {
 my $self = shift;

 my @tmplist = ();
 foreach my $dir (@{$self->{dirs}}) {
  push @tmplist, $dir;

  my $dh;
  if (!opendir($dh, $dir)) {
   $self->fatal("Unable to open directory [$dir].");
  }

  # Append new directories found in $dir to the end of our list of dirs
  # to iterate over.  Note: this could result in an infinite loop if following
  # symlinks was allowed.
  my @tmpdirs = grep {-d $_} map {$dir . '/' . $_} grep {!/^\.|CVS/} readdir($dh);
  closedir($dh);

  $self->{dirTree}{$dir} = \@tmpdirs;
  push @{$self->{dirs}}, @tmpdirs; 
 }

 @{$self->{dirs}} = @tmplist;
 return $self->{dirs};
} #_recursive_dirs
 
1;

__END__

=head1 NAME

Image::Gallery - Web image gallery creation.

=head1 SYNOPSIS

 use Image::Gallery;

=head1 ABSTRACT

 This module provides the interfaces for perl scripts to easily use
 Image::Gallery submodules and create html image galleries.

=head1 DESCRIPTION

This module provides the interfaces for perl scripts to easily use
Image::Gallery submodules and create html image galleries.  Using this module
very simple perl scripts can be written that create complete image galleries,
including thumb-nails, and allowing for customized html.

=head1 METHODS

=head2 new(\%config)

The new() constructor method instantiates a new Image::Gallery object.  A reference to a hash of configuration items may be passed as a parameter.

   my $gallery = Image::Gallery->new({dir => '',
                                      file => undef,
                                      recursive => undef,
                                      template_dir => undef,
                                      debug => undef});

For convenience configuration items may also be specified as a hash of items rather than as a hash reference.

   my $gallery = Image::Gallery->new(dir => '/usr/local/image_gallery/test/images',
                                     recursive => 1,
                                     template_dir => '/usr/local/image_gallery/test/templates',
                                     debug => 1);

If option I<file> is passed in, the gallery will be created based on that single image.  I<file> and I<dir> are mutually exclusive, and one of them is always required.

Option I<recursive> operates in conjunction with I<dir> for recursing into subdirectories.

I<template_dir> specifies the directory where the templates are located.

I<debug> Turns on debugging.  For Image::Gallery, any true value enables debugging.  Template module debugging constants can also be passed in to enable Template debugging.

 Template debugging example:
  use Image::Gallery;
  use Template::Constants ':all';
  my $gallery = Image::Gallery->new(dir => $dir,
                                    debug => DEBUG_ON | DEBUG_PARSER);

=head2 files(\%options)

The files() method returns a reference to a list of files.  It also normally assigns that value to the I<files> attribute of the object.

 my $files = $gallery->files({dir => $directory,
                              noassign => 1,
                              ignore => ['.caption',
                                         '.thumb_'];

No options need to be passed in.  By default the I<file> or I<dir> attributes will be used.  I<files> will be assigned to unless the option I<noassign> is passed in.

If attribute I<file> is set options I<dir> is not used.

Option I<dir> specifies a particular directory to find the files in.  Attribute I<dir> will be used if option I<dir> isn't passed in.

In the case where attribute I<recursive> is turned on, files() will only recurse if option I<noassign> isn't passed in.

Option I<noassign> prevents attribute I<files> from being assigned to by files().

Option I<ignore> is an arrayref of substrings of files that shouldn't be included in the list of files.  CVS and things beginning with . are always excluded from the list of files.

=head2 dirs()

dirs() method returns an arrayref to a list of directories starting from the
I<dir> attribute.  If the I<recursive> attribute is set then it will include all
subdirectories under I<dir>.  dirs() also assigns the arrayref to the I<dirs>
attribute.  CVS directories and directories beginning with . are always
excluded.

 $dirs = $gallery->dirs();
 
=head2 thumbs()

Method thumbs() writes out thumbnails for images in the I<files> attribute's
arrayref.

 $gallery->thumbs({format => 'png',
                   overwrite => 1,
                   percentage => 20,
                   prepend => '.gal_thumb_',
                   quality => 80});

=head2 captions()

Method captions() reads in .caption files found in I<dir> attribute.  It supports options I<allfiles> and I<existence> which are passed through to Image::Gallery::Caption.

 $gallery->captions({allfiles => 1,
                     existence => 1});

=head2 listCaptions()

Method listCaptions outputs .caption file information to STDOUT.  It accepts a printf formatting string to represent how to output the data.

 $gallery->listCaptions("key: %s value %s\n");

=head2 html()

Method html generates html output based on templates and .caption information.  It can work recursively if the I<recursive> attribute is set for the object.  A I<template_dir> can be specified as a hashref input option.  Additionally I<input> can point to a hashref of additional data to be utilized by the templates.

 $gallery->html({template_dir => '/usr/local/image_gallery/test/templates',
                 existence => 1,
                 input => {user => 'dleonard',
                           site_copyright => 2006}});

=head2 pagedHtml()

Method pagedHtml generates html output based on templates and .caption information.  It can work recursively if the I<recursive> attribute is set for the object.  A I<template_dir> can be specified as a hashref input option.  Additionally I<input> can point to a hashref of additional data to be utilized by the templates.  It will create as many pages of html as necessary for each page to contain at most I<page> images.  By default I<page> is set to 20.

 $gallery->pagedHtml({template_dir => '/usr/local/image_gallery/test/templates',
                      existence => 1,
                      input => {user => 'dleonard',
                                site_copyright => 2006},
                      page => 10});
=over

=back

=head1 AUTHOR

Douglas Leonard, E<lt>dleonard@dleonard.netE<gt>

L<https://github.com/dleonard04/image-gallery>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2026 by Douglas Leonard

This library is free software; you can redistribute it and/or modify it under the terms of the General Public License (GPL) version 2.  For more information, see http://www.fsf.org/licenses/gpl.txt

=cut
