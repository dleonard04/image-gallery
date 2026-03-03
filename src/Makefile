################################################################################
# $Id: Makefile,v 1.5 2008-08-19 16:17:19 dleonard Exp $
# $Date: 2008-08-19 16:17:19 $
#
# Makefile for Image::Gallery
################################################################################
BIN_PERM?=0775
DIR_PERM?=0775
LIB_PERM?=0664

BINDIR:=$(PREFIX)$(shell perl -V:installsitebin | sed "s/[';]//g" | sed "s/installsitebin=//")
LIBDIR:=$(PREFIX)$(shell perl -V:installsitelib | sed "s/[';]//g" | sed "s/installsitelib=//")

INSTALL_LIB?=$(LIBDIR)/Image
INSTALL_BIN?=$(BINDIR)

PWD:=$(shell pwd)

BIN:=generate_thumbs.pl \
     generate_websized.pl \
     read_caption.pl \
     write_html.pl \
     write_paged_html.pl

LIB:=Gallery.pm \
     Gallery/Caption.pm \
     Gallery/Common.pm \
     Gallery/Html.pm \
     Gallery/Thumb.pm

cfg:

install: image-bin image-lib

image-bin:
	@if [ "$(BINDIR)" = "UNKNOWN" ]; then \
	 echo "Unable to determine installsitebin" ; \
	 exit 1; \
	fi

	@echo "Installing scripts in $(INSTALL_BIN)"

	@mkdir -m $(DIR_PERM) -p $(INSTALL_BIN)

	@for i in $(BIN); do \
         cp $(PWD)/bin/$$i $(INSTALL_BIN)/. ;\
	 chmod $(BIN_PERM) $(INSTALL_BIN)/$$i ;\
        done

image-lib:
	@if [ "$(LIBDIR)" = "UNKNOWN" ]; then \
	 echo "Unable to determine installsitelib" ; \
	 exit 1; \
	fi

	@echo "Installing libraries in $(INSTALL_LIB)"

	@mkdir -m $(DIR_PERM) -p $(INSTALL_LIB)/Gallery

	@for i in $(LIB); do \
	 cp $(PWD)/lib/$$i $(INSTALL_LIB)/$$i ;\
	 chmod $(LIB_PERM) $(INSTALL_LIB)/$$i ;\
	done

dump-files: dump-bin dump-lib

dump-bin:
	@if [ "$(BINDIR)" = "UNKNOWN" ]; then \
	 echo "Unable to determine installsitebin" ; \
	 exit 1; \
	fi

	@files=`cd bin; find . -type f -print | grep -v CVS` ; \
	 for i in $$files; do \
	  echo $(INSTALL_BIN)/$$i | sed 's!/\.!!'; \
	 done

dump-lib:
	@if [ "$(LIBDIR)" = "UNKNOWN" ]; then \
	 echo "Unable to determine installsitelib" ; \
	 exit 1; \
	fi

	@files=`cd lib; find . -type f -print | grep -v CVS` ; \
	 for i in $$files; do \
	  echo $(INSTALL_LIB)/$$i | sed 's!/\.!!'; \
	 done
