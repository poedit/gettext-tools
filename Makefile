include versions.config

# version of the gettext-tools-windows package; usually same as GETTEXT_VERSION
# use "-n" suffix; for NuGet, use ".n" suffix instead, e.g. 0.20.1-1 and 0.20.1.1
PACKAGE_VERSION   = $(GETTEXT_VERSION)
NUGET_VERSION     = $(GETTEXT_VERSION)

# Awful trickery to undo MSYS's magical path conversion (see
# http://www.mingw.org/wiki/Posix_path_conversion) which happens to break
# gettext's executable relocation support.
MSYS_PREFIX       = c:/usr/local
UNIX_PREFIX       = /usr/local

RUNTIME_DIR       = /ucrt64/bin

LIBICONV_FLAGS    = --prefix=$(MSYS_PREFIX) \
					--disable-static \
					--disable-dependency-tracking \
					--disable-rpath \
					--disable-nls \
					--enable-relocatable

GETTEXT_FLAGS     = --prefix=$(MSYS_PREFIX) \
					--disable-static \
					--disable-dependency-tracking \
					--enable-silent-rules \
					--with-libiconv-prefix=$(USR_LOCAL) \
					--disable-rpath \
					--enable-nls \
					--disable-csharp \
					--disable-java \
					--enable-threads=windows \
					--enable-relocatable

CFLAGS  := -O2
LDFLAGS := -Wl,--dynamicbase -Wl,--nxcompat
NUGET   ?= nuget
CURL    ?= curl
CURLFLAGS ?= --fail --location --retry 5 --retry-all-errors

PATCHESDIR  = $(CURDIR)/patches
BUILDDIR    = $(CURDIR)/build
DOWNLOADDIR = $(BUILDDIR)/download
COMPILEDIR  = $(BUILDDIR)/compile
STAGEDIR    = $(BUILDDIR)/stage
USR_LOCAL   = $(STAGEDIR)/usr/local
DISTDIR     = $(BUILDDIR)/dist

ARCHIVE_FILE = $(BUILDDIR)/gettext-tools-windows-$(PACKAGE_VERSION).zip
NUGET_FILE   = $(BUILDDIR)/Gettext.Tools.$(NUGET_VERSION).nupkg

LIBICONV_FILE := libiconv-$(LIBICONV_VERSION).tar.gz
LIBICONV_URL  := http://ftpmirror.gnu.org/gnu/libiconv/$(LIBICONV_FILE)

GETTEXT_FILE := gettext-$(GETTEXT_VERSION).tar.xz
GETTEXT_URL  := http://ftpmirror.gnu.org/gnu/gettext/$(GETTEXT_FILE)

LIBICONV_DOWNLOAD := $(DOWNLOADDIR)/$(LIBICONV_FILE)
LIBICONV_COMPILE  := $(COMPILEDIR)/LIBICONV.built
LIBICONV_STAGE    := $(COMPILEDIR)/LIBICONV.staged

GETTEXT_DOWNLOAD := $(DOWNLOADDIR)/$(GETTEXT_FILE)
GETTEXT_COMPILE  := $(COMPILEDIR)/GETTEXT.built
GETTEXT_PATCHES  := $(wildcard $(PATCHESDIR)/gettext*)
GETTEXT_STAGE    := $(COMPILEDIR)/GETTEXT.staged


all: archive

download: $(LIBICONV_DOWNLOAD) $(GETTEXT_DOWNLOAD)
compile: $(LIBICONV_COMPILE) $(GETTEXT_COMPILE)
stage: $(LIBICONV_STAGE) $(GETTEXT_STAGE)


$(LIBICONV_DOWNLOAD):
	mkdir -p $(DOWNLOADDIR)
	$(CURL) $(CURLFLAGS) --output $@ $(LIBICONV_URL)
	test $(LIBICONV_SHA256) = `shasum -a256 $@ | cut -f1 -d" "`

$(LIBICONV_COMPILE): $(LIBICONV_DOWNLOAD)
	mkdir -p $(COMPILEDIR)
	tar -C $(COMPILEDIR) -xf $<
	cd $(COMPILEDIR)/libiconv-$(LIBICONV_VERSION) && \
		./configure $(LIBICONV_FLAGS) CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" && \
		$(MAKE)
	touch $@

$(LIBICONV_STAGE): $(LIBICONV_COMPILE)
	mkdir -p $(STAGEDIR)
	cd $(COMPILEDIR)/libiconv-$(LIBICONV_VERSION) && \
		$(MAKE) install DESTDIR=$(STAGEDIR) prefix=$(UNIX_PREFIX)
	touch $@



$(GETTEXT_DOWNLOAD):
	mkdir -p $(DOWNLOADDIR)
	$(CURL) $(CURLFLAGS) --output $@ $(GETTEXT_URL)
	test $(GETTEXT_SHA256) = `shasum -a256 $@ | cut -f1 -d" "`

$(GETTEXT_COMPILE): $(GETTEXT_DOWNLOAD) $(LIBICONV_COMPILE)
	mkdir -p $(COMPILEDIR)
	tar -C $(COMPILEDIR) -xf $<
	cd $(COMPILEDIR)/gettext-$(GETTEXT_VERSION) && \
	for p in $(GETTEXT_PATCHES) ; do \
		patch -p1 < $$p || exit 1 ; \
	done
	cd $(COMPILEDIR)/gettext-$(GETTEXT_VERSION) && \
		./configure -C $(GETTEXT_FLAGS) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	$(MAKE) -C $(COMPILEDIR)/gettext-$(GETTEXT_VERSION)
	touch $@

$(GETTEXT_STAGE): $(GETTEXT_COMPILE) $(LIBICONV_STAGE)
	mkdir -p $(STAGEDIR)
	$(MAKE) -C $(COMPILEDIR)/gettext-$(GETTEXT_VERSION) install DESTDIR=$(STAGEDIR) prefix=$(UNIX_PREFIX)
	rm -f $(STAGEDIR)$(UNIX_PREFIX)/share/locale/locale.alias
	touch $@


dist: stage
	rm -rf $(DISTDIR)
	mkdir -p $(DISTDIR)/{bin,lib/gettext,share,doc}
	cp -a LICENSE $(DISTDIR)/license.txt
	cp -a README.md $(DISTDIR)/readme.txt
	cp -a $(USR_LOCAL)/bin/msg*.exe $(DISTDIR)/bin/
	cp -a $(USR_LOCAL)/bin/recode-sr-latin.exe $(DISTDIR)/bin/
	cp -a $(USR_LOCAL)/bin/xgettext.exe $(DISTDIR)/bin/
	cp -a $(USR_LOCAL)/bin/*.dll $(DISTDIR)/bin/
	cp -a $(RUNTIME_DIR)/libgcc_s_seh*.dll $(DISTDIR)/bin
	cp -a $(RUNTIME_DIR)/libstdc++*.dll $(DISTDIR)/bin
	cp -a $(RUNTIME_DIR)/libgomp*.dll $(DISTDIR)/bin
	cp -a $(RUNTIME_DIR)/libwinpthread*.dll $(DISTDIR)/bin
	cp -a $(USR_LOCAL)/libexec/gettext/cldr-plurals.exe $(DISTDIR)/lib/gettext
	cp -a $(USR_LOCAL)/share/gettext-$(GETTEXT_VERSION) $(DISTDIR)/share/gettext
	cp -a $(USR_LOCAL)/share/gettext/styles $(DISTDIR)/share/gettext/
	cp -a $(USR_LOCAL)/share/locale $(DISTDIR)/share/
	cp -a $(USR_LOCAL)/share/doc/gettext/*.html $(DISTDIR)/doc/
	strip --strip-all $(DISTDIR)/bin/*.dll $(DISTDIR)/bin/*.exe


archive: dist
	rm -f $(ARCHIVE_FILE)
	cd $(DISTDIR) && zip -9 -r $(ARCHIVE_FILE) *

$(NUGET_FILE): Gettext.Tools.nuspec dist
	rm -f $@
	$(NUGET) pack Gettext.Tools.nuspec -Version $(NUGET_VERSION) -OutputDirectory $(BUILDDIR)

nuget: $(NUGET_FILE)

nuget-push: $(NUGET_FILE)
	$(NUGET) push $(NUGET_FILE) -Source https://www.nuget.org/api/v2/package

clean:
	rm -rf $(BUILDDIR)

.PHONY: all clean download compile stage dist archive nuget nuget-push
