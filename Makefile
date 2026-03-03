################################################################################
# image-gallery toplevel Makefile
#
# $Id: Makefile,v 1.11 2010-09-02 23:56:25 dleonard Exp $
# $Date: 2010-09-02 23:56:25 $
################################################################################
SHELL=/bin/sh
RPM=/usr/bin/rpmbuild

PKG=image-gallery

VERSION?=003
RELEASE?=$(shell date +%Y%m%d%H%M%S)


cfg:

build:

deb debian deb-bin: _FAKE_
	@echo "Building debian package"
	dpkg-buildpackage --sign-key=$(SIGN_KEY) -B

deb-src:
	@echo "Building debian src package"
	dpkg-buildpackage -S

tgz:
	@echo "Tar-ing up complete tree"
	@cd .. ; \
	tar --exclude=CVS -czf image-gallery_$(VERSION)-$(RELEASE).tgz image_gallery

slackware:
	@echo "Slackware not yet implemented"

# RPM build
USRDIR=$(shell rpm --showrc | grep "\-14: _usr" | grep -v % | awk '{print $$3}')
USRSRCDIR=$(shell rpm --showrc | grep "\-14: _usrsrc" | awk '{print $$3}' | sed 's!%{_usr}!$(USRDIR)!')
TOPDIR=$(shell rpm --showrc | grep "\-14: _topdir" | awk '{print $$3}' | sed 's!%{_usrsrc}!$(USRSRCDIR)!' | sed 's!%{getenv:HOME}!$(HOME)!')
BUILDDIR=$(shell rpm --showrc | grep "\-14: _builddir" | awk '{print $$3}' | sed 's!%{_topdir}!$(TOPDIR)!')
RPMDIR=$(shell rpm --showrc | grep "\-14: _rpmdir" | awk '{print $$3}' | sed 's!%{_topdir}!$(TOPDIR)!')
SOURCEDIR=$(shell rpm --showrc | grep "\-14: _sourcedir" | awk '{print $$3}' | sed 's!%{_topdir}!$(TOPDIR)!')
SPECDIR=$(shell rpm --showrc | grep "\-14: _specdir" | awk '{print $$3}' | sed 's!%{_topdir}!$(TOPDIR)!')
SRCRPMDIR=$(shell rpm --showrc | grep "\-14: _srcrpmdir" | awk '{print $$3}' | sed 's!%{_topdir}!$(TOPDIR)!')

TARBALL=$(PKG)-$(VERSION).tgz
SPEC_FILE=rpm/$(PKG).spec

rpm redhat: _FAKE_
	@echo "Building RPM package and RPM src package"

	# Create RPM building directories if necessary
	@mkdir -p $(BUILDDIR)
	@mkdir -p $(RPMDIR)
	@mkdir -p $(SOURCEDIR)
	@mkdir -p $(SPECDIR)
	@mkdir -p $(SRCRPMDIR)

	# Create a source tarball
	@cp -a src $(PKG)-$(VERSION)
	@tar -czf $(TARBALL) $(PKG)-$(VERSION)
	@rm -rf $(PKG)-$(VERSION)
	@mv $(TARBALL) $(SOURCEDIR)/.

	# Modify the specfile to have the correct files listed in it.
	@cp $(SPEC_FILE) $(SPEC_FILE).original
	@tmpfile=$(SPEC_FILE).new; \
	 line=`grep -n %files $(SPEC_FILE) | awk -F: '{print $$1}'`; \
	 head -n $$line $(SPEC_FILE) >$$tmpfile ;\
	 mv $$tmpfile $(SPEC_FILE)
	$(MAKE) -s -C src dump-files >>$(SPEC_FILE)

	# Replace the package name
	@perl -pi -e 's/Name: .*/Name: $(PKG)/' $(SPEC_FILE)

	# Replace the version
	@perl -pi -e 's/Version: .*/Version: $(VERSION)/' $(SPEC_FILE)

	# Increment the release number
	@perl -pi -e 's/Release: .*/Release: $(RELEASE)/' $(SPEC_FILE)

	# Build RPM
	@rpmbuild -ba --clean $(SPEC_FILE)

# Build an rpm via ant
ant-rpm:
	@echo "Building RPM package and RPM src package using ant"
	cd rpm; \
	 ant rpm

install:
	@echo "Installing image-gallery"
	$(MAKE) -C src install

clean: clean-ant clean-deb clean-rpm

clean-ant:
	@if [ -d staging ]; then \
	 rm -r staging; \
	fi

clean-deb:
	@if [ -f build-stamp ]; then \
	 rm build-stamp; \
	fi
	@if [ -f configure-stamp ]; then \
	 rm configure-stamp; \
	fi
	-rm ../image-gallery_*.changes
	-rm ../image-gallery_*.dsc
	-rm ../image-gallery_*.deb
	-rm ../image-gallery_*.tar.gz

clean-rpm:
	@if [ -f $(SPEC_FILE).original ]; then \
	 mv $(SPEC_FILE).original $(SPEC_FILE); \
	fi

_FAKE_:
