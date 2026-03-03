################################################################################
# $Id: Makefile,v 1.6 2010-02-01 08:24:58 dleonard Exp $
# $Date: 2010-02-01 08:24:58 $
#
# Makefile for Image::Gallery test directory
################################################################################
BIN_PERM?=0775
DIR_PERM?=0775
LIB_PERM?=0664

INSTALL ?= /usr/local/image_gallery
INSTALL_TEST ?= $(INSTALL)/test
INSTALL_TEST_CSS = $(INSTALL_TEST)/css
INSTALL_TEST_IMAGES = $(INSTALL_TEST)/images
INSTALL_TEST_TEMPLATES = $(INSTALL_TEST)/templates

PWD := $(shell pwd)

IMAGES:=.caption \
        havok_w1.jpg \
        presen_1.jpg \
        ranma1.jpg \
        unipuma1.jpg \
        white_01.jpg

CSS:=default.css \
     image.css

TEMPLATES:=body \
           body_paged \
           footer \
           header

install: install-css install-images install-templates

install-css:
	@echo "Installing test css"
	@mkdir -m $(DIR_PERM) -p $(INSTALL_TEST_CSS)

	@for i in $(CSS); do \
	 cp $(PWD)/css/$$i $(INSTALL_TEST_CSS)/. ;\
	done

install-images:
	@echo "Installing test images and .caption files"
	@mkdir -m $(DIR_PERM) -p $(INSTALL_TEST_IMAGES)/recurse

	@for i in $(IMAGES); do \
	 cp $(PWD)/$$i $(INSTALL_TEST_IMAGES)/. ;\
	done
	@cp $(PWD)/.caption_2 $(INSTALL_TEST_IMAGES)/recurse/.caption
	@cp $(PWD)/white_01.jpg $(INSTALL_TEST_IMAGES)/recurse/.

install-templates:
	@echo "Installing test templates"
	@mkdir -m $(DIR_PERM) -p $(INSTALL_TEST_TEMPLATES)

	@for i in $(TEMPLATES); do \
	 cp $(PWD)/templates/$$i $(INSTALL_TEST_TEMPLATES)/. ;\
	done

distclean: clean clean_thumb

clean:
	@echo "Removing test index.html pages"
	@index=`find $(INSTALL_TEST_IMAGES) -type f -name index.html -print` ; \
	 if [ "$$index" ]; then \
	  rm $$index ; \
	 fi

clean_thumb:
	@echo "Removing test thumbnails"
	@files=`find $(INSTALL_TEST_IMAGES) -type f -print | grep "\.thumb"` ; \
	 if [ "$$files" ]; then \
	  rm $$files ; \
	 fi
