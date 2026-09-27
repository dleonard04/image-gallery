# Image Gallery toolkit

## Release: 004

Collection of Perl modules and scripts for generating static HTML image
galleries from directories of images. Release 004 modernizes the Debian and RPM
build systems for current distributions.

Project home: <https://github.com/dleonard04/image-gallery>

## Overview

This collection of Perl modules and scripts creates image galleries based on
directories of images. It uses PerlMagick to resize images and create
thumbnails, and generates HTML output using the Template Toolkit.

The codebase can be installed directly, built as an RPM package, or built as a
Debian package. The Debian packaging targets Debian 12 ("bookworm") and newer
(debhelper compat 13) and Ubuntu 22.04 and newer; the RPM packaging builds on
current Red Hat and Amazon Linux releases.

## Building and installing

See the [top-level Make targets](#relevant-top-level-make-targets) below. In
brief:

- `make install` installs the modules and scripts on the local machine.
- `make deb` / `make deb-src` build Debian binary and source packages.
- `make rpm` / `make ant-rpm` build RPM packages.

## Copyright

See [doc/copyright.txt](doc/copyright.txt). The codebase is licensed under the
GPLv2 (see [LICENSE.txt](LICENSE.txt)).

## Dependencies

Runtime dependencies are Perl with `Image::Magick` (PerlMagick) and `Template`
(Template Toolkit). See [doc/dependencies.txt](doc/dependencies.txt) for the
package names and install commands on Debian/Ubuntu and RHEL/Amazon Linux, plus
the build-time dependencies.

## Usage

Each script supports `--help`:

```sh
generate_thumbs.pl --help
generate_websized.pl --help
read_caption.pl --help
write_html.pl --help
write_paged_html.pl --help
```

## Specifications

- [Caption file format](doc/caption_file_spec.txt)

## Relevant top-level Make targets

| Target    | Description                                                    |
| --------- | -------------------------------------------------------------- |
| `deb`     | Build a Debian package                                         |
| `deb-src` | Build a Debian source package                                  |
| `rpm`     | Build an RPM package and RPM source package                   |
| `ant-rpm` | Build an RPM package and source package via the ant rpm target |
| `install` | Install the code on the local machine                         |
| `clean`   | Restore the source tree                                       |
