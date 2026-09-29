# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, GitHub Copilot, and
others) when working with code in this repository.

## Overview

`image-gallery` is a Perl toolkit that generates static HTML image galleries from
directories of images. It resizes images via PerlMagick (ImageMagick) to make
thumbnails and web-sized copies, reads per-directory `.caption` metadata files, and
renders pages through Template Toolkit templates. Distributed as a Debian or RPM
package, or installed directly.

## Layout

- `src/lib/` — the `Image::Gallery` Perl modules (the actual logic).
- `src/bin/` — thin CLI wrappers that parse options and drive the modules.
- `test/` — sample images, `.caption` files, CSS, and templates used as the default
  data set (installed under `/usr/local/image_gallery/test/`), plus `run_tests.pl`,
  the functional test wrapper (run it with `make test`).
- `debian/`, `rpm/` — packaging.
- `doc/` — README, dependency list, and the `.caption` file format spec.

## Architecture

`Image::Gallery` (`src/lib/Gallery.pm`) is the façade. A script constructs one object
with a `dir` (or single `file`), optional `recursive`, and `template_dir`, then calls
methods in a pipeline:

1. `captions()` → builds an `Image::Gallery::Caption` object per directory and parses
   its `.caption` file.
2. `thumbs()` → for each image, builds an `Image::Gallery::Thumb`, scales it, writes it.
3. `html()` / `pagedHtml()` → builds an `Image::Gallery::Html` per directory and renders
   `index.html` (or paginated `indexNN.html`) from templates.

Key design points:

- **Module hierarchy.** Every module `@ISA`-inherits `Image::Gallery::Common`, which
  provides shared logging (`logger` via syslog, `error`, `fatal` — note `fatal` calls
  `exit 1`), `debug`, `md5`, and directory helpers. Errors are fatal by design.
- **Option-passing convention.** Nearly every method accepts either a hashref or a flat
  `%options` hash — the `if (! ref $options) { shift; $options = {@_} }` idiom at the top
  of methods handles both. Follow it when adding methods.
- **Caption accessors are generated.** `Gallery/Caption.pm` builds one accessor sub per
  field (`artist`, `title`, `date`, …) at load time by `eval`-ing code in a loop over
  `@Image::Gallery::Caption::Fields`. To add a caption field, add it to that array (and,
  if it maps to EXIF, to `%Exif`); do not hand-write accessors.
- **Thumbnail naming.** Thumbs are named by prepending `.thumb_` (constant `PREPEND`) or
  postpending `_thumb`/`x950` to the base filename. `thumbs()` builds an ignore list so
  it never re-scales existing thumbnails, `.caption`, or `.html` files. `generate_websized.pl`
  reuses the same `thumbs()` path but postpends `x950` and uses width 950 to make full-size
  web copies rather than small thumbnails.
- **Recursion.** `_recursive` / `_recursive_dirs` walk directories iteratively (appending
  to a worklist). Symlinks are deliberately not followed to avoid infinite loops. Entries
  matching `/^\.|CVS/` (dotfiles and CVS) are excluded everywhere.
- **Templates.** `Gallery/Html.pm` wraps Template Toolkit. Templates in `test/templates/`
  (`header`, `body`, `body_paged`, `footer`) receive a data hash keyed on filename whose
  values mirror the caption fields, plus `subdirs`, `stylesheet`, `favicon`, `title`,
  `date`, and pagination vars (`previous_page`, `next_page`, `current_page`).

## `.caption` files

One `.caption` file per directory (not recursive — each directory needs its own). Format
is `key = value` lines, values optionally quoted; entries grouped under `file = NAME`.
Only keys in `@Image::Gallery::Caption::Fields` are honored; unknown keys are silently
skipped. Full spec: `doc/caption_file_spec.txt`. `sequence` controls display order
(see `captionSort`), falling back to alphabetical.

## Common commands

The CLI scripts default to reading/writing the sample data under
`/usr/local/image_gallery/test/`; pass `--dir` to target real directories. Every script
supports `--help`.

```sh
# Generate thumbnails (default width 150px, recursive)
perl src/bin/generate_thumbs.pl --dir=/path/to/images

# Generate web-sized copies (default width 950px, postpended "x950")
perl src/bin/generate_websized.pl --dir=/path/to/images

# Render gallery HTML (add --thumbs to also build thumbnails first)
perl src/bin/write_html.pl --dir=/path/to/images --thumbs

# Render paginated HTML (--page = images per page)
perl src/bin/write_paged_html.pl --dir=/path/to/images --page=20

# Read/dump caption data
perl src/bin/read_caption.pl --dir=/path/to/images
```

Note: `read_caption.pl` has a hardcoded demo line printing the `title` of `havok_w1.jpg`;
it assumes the sample data set.

Loading the modules from the checkout is not just `-Isrc/lib`: the packages are
`Image::Gallery::*` but the files live directly under `src/lib` (as `Gallery.pm` etc.),
so Perl needs to find them beneath an `Image/` directory. `test/run_tests.pl` handles
this by staging a temporary `Image -> src/lib` symlink; do the same for ad-hoc runs, or
`make install` first.

## Tests

`make test` runs `test/run_tests.pl`, a functional wrapper that checks its dependencies
(printing per-distro install commands and exiting if `Image::Magick` or `Template` is
missing), then exercises caption parsing, thumbnail and web-size generation, and HTML
output against the sample data. It uses `Test::More` (TAP), so `prove test/run_tests.pl`
works too.

## Build & install

Top-level `Makefile` targets:

```sh
make install      # install modules + scripts locally (delegates to src/Makefile)
make test         # run the functional test wrapper (test/run_tests.pl)
make deb          # build a Debian binary package (dpkg-buildpackage -b; -us -uc unless SIGN_KEY set)
make deb-src      # build a Debian source package
make rpm          # build RPM + src RPM (rewrites rpm/image-gallery.spec %files from src)
make ant-rpm      # build RPM via rpm/build.xml (ant)
make clean        # restore the source tree (removes staging + generated packaging files)
```

`src/Makefile` installs into Perl's `installsitebin` / `installsitelib` (queried from
`perl -V`, i.e. `/usr/local/...` on Debian), placing modules under `.../Image/Gallery/`.
Its `dump-files` target emits the installed-file list that the `rpm` target splices into
the spec's `%files` section — so adding a module or script means adding it to the `BIN` /
`LIB` variables in `src/Makefile`. The Debian package overrides `INSTALL_BIN`/`INSTALL_LIB`
in `debian/rules` to the Perl *vendor* dirs (`/usr/bin`, `/usr/share/perl5`), since
`dh_usrlocal` forbids a package shipping files under `/usr/local`. The RPM target derives
its build tree from `rpm --eval` (overridable via `make rpm TOPDIR=...`).

## Dependencies

Runtime: Perl (only core modules beyond these) plus `Image::Magick` (PerlMagick) and
`Template` (Template Toolkit). See `doc/dependencies.txt` for per-distro package names
(Debian/Ubuntu and RHEL/Amazon Linux) and build-time dependencies.

## Notes for changes

- The repo was imported from CVS; modules still carry `$Id$`/`$Date$` header keywords and
  the directory walkers still filter out `CVS`. Removing these CVS-isms is expected cleanup.
- `Gallery/Caption.pm` has `TODO`s: `write()` lacks `dir_captions` support, and `files()`
  predates the `getFiles`/`getSubdirectories` helpers in `Common.pm`.
