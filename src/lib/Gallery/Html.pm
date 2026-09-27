package Image::Gallery::Html;
################################################################################
# $Id: Html.pm,v 1.25 2007-06-19 05:52:01 dleonard Exp $
# $Date: 2007-06-19 05:52:01 $
#
# Html output library for Image::Gallery
################################################################################
use strict;

use Template;

use Image::Gallery::Common;
use vars '@ISA';
@ISA = 'Image::Gallery::Common';

################################################################################
# new
#  Note: 'input' should be a hashref to a hash keyed on filename with each value
#        consisting of a hashref that looks like
#        %Image::Gallery::Caption::Fields
################################################################################
sub new {
 my ($class, $options) = @_;
 if (! ref $options) {
  shift;
  $options = scalar @_ ? {@_} : {};
 }

 my $self = {date => undef,
             debug => undef,
             dir => undef,
             file => 'index.html',
             input => {},
             post_process => undef,  # templates that should be processed afterwards
             pre_process => undef,   # templates that should be processed beforehand
             template_dir => '/usr/local/image_gallery/test/templates',
             template => 'body',
             title => undef};

 foreach (keys %$self) {
  $self->{$_} = $options->{$_} if exists $options->{$_};
 }

 if (!$self->{file}) {
  $class->fatal('No file specified.'); 
 }
 if (!$self->{dir}) {
  $class->fatal('No directory specified.'); 
 }
 if (!$self->{template_dir}) {
  $class->fatal('No template directory specified.');
 }

 # Set title to basename(file) if it isn't set
 if (!$self->{title}) {
  ($self->{title} = $self->{file}) =~ s#.*?([^/]+)$#$1#;
 }

 my %template_hash = (INCLUDE_PATH => $self->{template_dir},
                      OUTPUT_PATH => $self->{dir},
                      POST_PROCESS => $self->{post_process},
                      PRE_PROCESS => $self->{pre_process});

 $template_hash{DEBUG} = $self->{debug} if defined $self->{debug};

 $self->{_template} = Template->new(%template_hash);
 if (!$self->{_template}) {
  $class->fatal('Unable to create template object. ' . $!);
 }

 bless $self, $class;

 # Set date after creating object
 $self->SUPER::date();

 return $self;
} #new

################################################################################
# write_file
# I: $file         # Output file
#    $template     # Template file
#    $input        # Hashref of input data
# O: $file on success
################################################################################
sub write_file {
 my ($self, $file, $template, $input) = @_;
 if (!defined $file) {
  $self->debug('Using default file [' . $self->{file} . '].');
  $file = $self->{file};
 }
 if (!defined $template) {
  $self->debug('Using default template [' . $self->{template} . '].');
  $template = $self->{template};
 }
 if (!defined $input) {
  $self->debug('Using default input data.');
  $input = $self->{input};
 }

 $input->{date} ||= $self->{date};
 $input->{title} ||= $self->{title};

 if (!$self->{_template}->process($template, $input, $file)) {
  $self->fatal($self->{_template}->error());
 }

 return $file;
} #write_file

1;

__END__

=head1 NAME

Image::Gallery::Html - Web image gallery html output stage

=head1 SYNOPSIS

 use Image::Gallery::Html;

=head1 ABSTRACT

This module provides a mechanism for outputting html pages utilizing Template Toolkit templates, and Image::Gallery data.

=head1 DESCRIPTION

This modules outputs an html page for Image::Gallery.  It utilizes the Template Toolkit to abstract the html from the code.

=head1 METHODS

=head2 new(\%config)

The new() constructor method instantiates a new Image::Gallery:Html object.  A reference to a hash of configuration items may be passed in as a parameter.

 my $html = Image::Gallery::Html->new({date => undef,
                                       debug => undef,
                                       dir => undef,
                                       file => 'index.html',
                                       input => {},
                                       paged => undef,
                                       post_process => undef,
                                       pre_process => undef,
                                       template_dir => '/usr/local/image_gallery/test/templates',
                                       template => 'body',
                                       title => undef};

For convenience configuration attributes may also be passed in as a hash rather than a hash reference.

 my $html = Image::Gallery::Html->new(dir => '/var/tmp');

Options I<dir>, I<file>, and I<template_dir> are required.  All other options listed above are optional.  I<file> and I<template_dir> have the above default values.   Option I<date> is set to the current date-time in standard XML date format if not passed in.  Option I<input> is a ref to a hash of data used as the default dataset for populating a template.  I<post_process> and I<pre_process> are passed through to C<Template> as POST_PROCESS and PRE_PROCESS attributes.  I<title> is derived from the basename of I<file> if it is not specified.

=head2 write_file($file, $template, $input)

write_file() writes out an output file, C<$file> based on an input template, C<$template>.  C<$input> is a reference to a hash of data used to populate C<$template>.  If any of the input variables are not defined, the current object's equivalent attributes are used instead.

=over

=back

=head1 AUTHOR

Douglas Leonard, E<lt>dleonard@dleonard.netE<gt>

L<https://github.com/dleonard04/image-gallery>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2026 by Douglas Leonard

This library is free software; you can redistribute it and/or modify it under the terms of the General Public License (GPL) version 2.  For more information, see http://www.fsf.org/licenses/gpl.txt

=cut

