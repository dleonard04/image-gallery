Summary: Perl image gallery generation tools
Name: @PKG@
Version: @VERSION@
Release: @RELEASE@
Source: %{name}-%{version}.tgz
License: copyright 2006-2010 Douglas Leonard
Group: Applications/System
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
Perl scripts for creating image galleries.  Generates thumbnails.  Handles reading caption files or generating captions based on image information.  Generates HTML pages based on Template Toolkit templates.

%prep

%setup -q
rm -rf $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT

%build

%install
make install PREFIX=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
@FILES@
