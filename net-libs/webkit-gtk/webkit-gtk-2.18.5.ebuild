# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
CMAKE_MAKEFILE_GENERATOR="ninja"
PYTHON_COMPAT=( python2_7 )
USE_RUBY="ruby22 ruby23 ruby24"

inherit check-reqs cmake-utils eutils flag-o-matic gnome2 pax-utils python-any-r1 ruby-single toolchain-funcs versionator virtualx \
	multilib multilib-minimal

MY_P="webkitgtk-${PV}"
DESCRIPTION="Open source web browser engine"
HOMEPAGE="http://www.webkitgtk.org/"
SRC_URI="http://www.webkitgtk.org/releases/${MY_P}.tar.xz"

LICENSE="LGPL-2+ BSD"
SLOT="4/37" # soname version of libwebkit2gtk-4.0
KEYWORDS="~alpha amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~x86-macos"

IUSE="aqua coverage doc +egl +geolocation gles2 gnome-keyring +gstreamer +introspection +jit libnotify nsplugin +opengl spell wayland +webgl X"
IUSE+=" bmalloc threaded-compositor accelerated-overflow-scrolling ftl-jit accelerated-2d-canvas hardened"

# webgl needs gstreamer, bug #560612
REQUIRED_USE="
	geolocation? ( introspection )
	gles2? ( egl )
	introspection? ( gstreamer )
	nsplugin? ( X )
	webgl? ( ^^ ( gles2 opengl ) )
	!webgl? ( ?? ( gles2 opengl ) )
	webgl? ( gstreamer )
	wayland? ( egl )
	|| ( aqua wayland X )
	accelerated-2d-canvas? ( webgl !gles2 )
	hardened? ( !jit )
"
#REQUIRED_USE+=" jit" #breaks google.com without it

# Tests fail to link for inexplicable reasons
# https://bugs.webkit.org/show_bug.cgi?id=148210
RESTRICT="test"

# Aqua support in gtk3 is untested
# Dependencies found at Source/cmake/OptionsGTK.cmake
# Various compile-time optionals for gtk+-3.22.0 - ensure it
# Missing OpenWebRTC checks and conditionals, but ENABLE_MEDIA_STREAM/ENABLE_WEB_RTC is experimental upstream (PRIVATE OFF)
RDEPEND="
	>=x11-libs/cairo-1.10.2:=
	>=media-libs/fontconfig-2.8.0:1.0
	>=media-libs/freetype-2.4.2:2
	>=dev-libs/libgcrypt-1.6.0:0=
	>=x11-libs/gtk+-3.22:3[aqua?,introspection?,wayland?,X?,${MULTILIB_USEDEP}]
	>=media-libs/harfbuzz-1.3.3:=[icu(+)]
	>=dev-libs/icu-3.8.1-r1:=
	virtual/jpeg:0=
	>=net-libs/libsoup-2.48:2.4[introspection?,${MULTILIB_USEDEP}]
	>=dev-libs/libxml2-2.8.0:2
	>=media-libs/libpng-1.4:0=
	dev-db/sqlite:3=
	sys-libs/zlib:0
	>=dev-libs/atk-2.8.0
	media-libs/libwebp:=[${MULTILIB_USEDEP}]

	>=dev-libs/glib-2.40:2
	>=dev-libs/libxslt-1.1.7
	gnome-keyring? ( app-crypt/libsecret )
	geolocation? ( >=app-misc/geoclue-2.1.5:2.0 )
	introspection? ( >=dev-libs/gobject-introspection-1.32.0:= )
	dev-libs/libtasn1:=
	>=dev-libs/libgcrypt-1.7.0:0=
	nsplugin? ( >=x11-libs/gtk+-2.24.10:2[${MULTILIB_USEDEP}] )
	spell? ( >=app-text/enchant-0.22:=[${MULTILIB_USEDEP}] )
	gstreamer? (
		>=media-libs/gstreamer-1.2.3:1.0[${MULTILIB_USEDEP}]
		>=media-libs/gst-plugins-base-1.2.3:1.0[${MULTILIB_USEDEP}]
		>=media-libs/gst-plugins-bad-1.10:1.0[opengl?,egl?,${MULTILIB_USEDEP}] )

	X? (
		x11-libs/cairo[X]
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXdamage
		x11-libs/libXrender
		x11-libs/libXt )
	ftl-jit? ( >=sys-devel/llvm-3.5.0 )
	dev-libs/gmp[-pgo]

	libnotify? ( x11-libs/libnotify[${MULTILIB_USEDEP}] )
	dev-libs/hyphen[${MULTILIB_USEDEP}]

	egl? ( media-libs/mesa[egl] )
	gles2? ( media-libs/mesa[gles2] )
	opengl? ( virtual/opengl
		x11-libs/cairo[opengl] )
	webgl? (
		x11-libs/cairo[opengl]
		x11-libs/libXcomposite
		x11-libs/libXdamage )
"

# paxctl needed for bug #407085
# Need real bison, not yacc
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	${RUBY_DEPS}
	>=app-accessibility/at-spi2-core-2.5.3
	>=dev-lang/perl-5.10
	>=dev-util/gtk-doc-am-1.10
	>=dev-util/gperf-3.0.1
	>=sys-devel/bison-2.4.3
	|| ( >=sys-devel/gcc-4.9 >=sys-devel/clang-3.3 )
	sys-devel/gettext
	virtual/pkgconfig

	dev-lang/perl
	virtual/perl-Data-Dumper
	virtual/perl-Carp

	doc? ( >=dev-util/gtk-doc-1.10 )
	geolocation? ( dev-util/gdbus-codegen )
	introspection? ( jit? ( sys-apps/paxctl ) )
	test? (
		dev-lang/python:2.7
		dev-python/pygobject:3[python_targets_python2_7]
		x11-themes/hicolor-icon-theme
		jit? ( sys-apps/paxctl ) )
"

S="${WORKDIR}/${MY_P}"

CHECKREQS_DISK_BUILD="18G" # and even this might not be enough, bug #417307

pkg_pretend() {
	if [[ ${MERGE_TYPE} != "binary" ]] ; then
		if is-flagq "-g*" && ! is-flagq "-g*0" ; then
			einfo "Checking for sufficient disk space to build ${PN} with debugging CFLAGS"
			check-reqs_pkg_pretend
		fi

		if ! test-flag-CXX -std=c++14 ; then
			die "You need at least GCC 5.2.x or Clang >= 3.5 for C++14-specific compiler flags"
		fi

		if tc-is-gcc && [[ $(gcc-version) < 4.9 ]] ; then
			die 'The active compiler needs to be gcc 4.9 (or newer)'
		fi
	fi
}

pkg_setup() {
	if [[ ${MERGE_TYPE} != "binary" ]] && is-flagq "-g*" && ! is-flagq "-g*0" ; then
		check-reqs_pkg_setup
	fi

	python-any-r1_pkg_setup
}

src_prepare() {
	# https://bugs.gentoo.org/show_bug.cgi?id=555504
	eapply "${FILESDIR}"/${PN}-2.8.5-fix-ia64-build.patch
	epatch "${FILESDIR}"/fix-ftbfs-x86.patch
	cmake-utils_src_prepare
	gnome2_src_prepare

	multilib_copy_sources
}

multilib_src_configure() {
	# Respect CC, otherwise fails on prefix #395875
	tc-export CC

	# Arches without JIT support also need this to really disable it in all places
	use jit || append-cppflags -DENABLE_JIT=0 -DENABLE_YARR_JIT=0 -DENABLE_ASSEMBLER=0

	# It does not compile on alpha without this in LDFLAGS
	# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=648761
	use alpha && append-ldflags "-Wl,--no-relax"

	# ld segfaults on ia64 with LDFLAGS --as-needed, bug #555504
	use ia64 && append-ldflags "-Wl,--no-as-needed"

	# Sigbuses on SPARC with mcpu and co., bug #???
	use sparc && filter-flags "-mvis"

	# https://bugs.webkit.org/show_bug.cgi?id=42070 , #301634
	use ppc64 && append-flags "-mminimal-toc"

	# Try to use less memory, bug #469942 (see Fedora .spec for reference)
	# --no-keep-memory doesn't work on ia64, bug #502492
	if ! use ia64; then
		append-ldflags "-Wl,--no-keep-memory"
	fi

	# We try to use gold when possible for this package
#	if ! tc-ld-is-gold ; then
#		append-ldflags "-Wl,--reduce-memory-overheads"
#	fi

	# Multiple rendering bugs on youtube, github, etc without this, bug #547224
	append-flags $(test-flags -fno-strict-aliasing)

	append-cxxflags "-std=c++14"

	local ruby_interpreter=""

	if has_version "virtual/rubygems[ruby_targets_ruby24]"; then
		ruby_interpreter="-DRUBY_EXECUTABLE=$(type -P ruby24)"
	elif has_version "virtual/rubygems[ruby_targets_ruby23]"; then
		ruby_interpreter="-DRUBY_EXECUTABLE=$(type -P ruby23)"
	elif has_version "virtual/rubygems[ruby_targets_ruby22]"; then
		ruby_interpreter="-DRUBY_EXECUTABLE=$(type -P ruby22)"
	else
		ruby_interpreter="-DRUBY_EXECUTABLE=$(type -P ruby21)"
	fi

	# TODO: Check Web Audio support
	# should somehow let user select between them?
	#
	# FTL_JIT requires llvm
	#
	# opengl needs to be explicetly handled, bug #576634

	local opengl_enabled
	if use opengl || use gles2; then
		opengl_enabled=ON
	else
		opengl_enabled=OFF
	fi

	# support for webgl (aka 2d-canvas accelerating)
	local canvas_enabled
	if use webgl && ! use gles2 ; then
		canvas_enabled=ON
	else
		canvas_enabled=OFF
	fi

	local mycmakeargs=(
		-DENABLE_QUARTZ_TARGET=$(usex aqua)
		-DENABLE_API_TESTS=$(usex test)
		-DENABLE_GTKDOC=$(usex doc)
		-DENABLE_GEOLOCATION=$(usex geolocation)
		$(cmake-utils_use_find_package gles2 OpenGLES2)
		-DENABLE_GLES2=$(usex gles2)
		-DENABLE_VIDEO=$(usex gstreamer)
		-DENABLE_WEB_AUDIO=$(usex gstreamer)
		-DENABLE_INTROSPECTION=$(usex introspection)
		-DENABLE_JIT=$(usex jit)
		-DUSE_LIBNOTIFY=$(usex libnotify)
		-DUSE_LIBSECRET=$(usex gnome-keyring)
		-DENABLE_PLUGIN_PROCESS_GTK2=$(usex nsplugin)
		-DENABLE_SPELLCHECK=$(usex spell)
		-DENABLE_WAYLAND_TARGET=$(usex wayland)
		-DENABLE_WEBGL=$(usex webgl)
		$(cmake-utils_use_find_package egl EGL)
		$(cmake-utils_use_find_package opengl OpenGL)
		-DENABLE_X11_TARGET=$(usex X)
		-DENABLE_OPENGL=${opengl_enabled}
		-DENABLE_ACCELERATED_2D_CANVAS=$(usex accelerated-2d-canvas)
		-DCMAKE_BUILD_TYPE=Release
		-DPORT=GTK
		${ruby_interpreter}
		-DENABLE_THREADED_COMPOSITOR=$(usex threaded-compositor)
		-DENABLE_ACCELERATED_OVERFLOW_SCROLLING=$(usex accelerated-overflow-scrolling)
		-DENABLE_FTL_JIT=$(usex ftl-jit)
		-DUSE_SYSTEM_MALLOC=$(usex bmalloc)
	)

	# Allow it to use GOLD when possible as it has all the magic to
	# detect when to use it and using gold for this concrete package has
	# multiple advantages and is also the upstream default, bug #585788
#	if tc-ld-is-gold ; then
#		mycmakeargs+=( -DUSE_LD_GOLD=ON )
#	else
#		mycmakeargs+=( -DUSE_LD_GOLD=OFF )
#	fi

	mycmakeargs+=( -DCMAKE_INSTALL_LIBEXECDIR=$(get_libdir)/misc )
	mycmakeargs+=( -DCMAKE_INSTALL_BINDIR=$(get_libdir)/webkit-gtk )
	mycmakeargs+=( -DCMAKE_LIBRARY_PATH=/usr/$(get_libdir) )

	#used to properly control cross compile with debian fix-ftbfs-x86.patch
	if use abi_x86_64 ; then
		mycmakeargs+=( -DCMAKE_CXX_LIBRARY_ARCHITECTURE="x86_64-pc-linux-gnu" )
	elif use abi_x86_32 ; then
		mycmakeargs+=( -DCMAKE_CXX_LIBRARY_ARCHITECTURE="i686-pc-linux-gnu" )
	fi

	cmake-utils_src_configure
}

multilib_src_compile() {
	cmake-utils_src_compile
}

multilib_src_test() {
	# Prevents test failures on PaX systems
	use jit && pax-mark m $(list-paxables Programs/*[Tt]ests/*) # Programs/unittests/.libs/test*

	cmake-utils_src_test
}

multilib_src_install() {
	cmake-utils_src_install

	# Prevents crashes on PaX systems, bug #522808
	use jit && pax-mark m "${ED}usr/libexec/webkit2gtk-4.0/jsc" "${ED}usr/libexec/webkit2gtk-4.0/WebKitWebProcess"
	pax-mark m "${ED}usr/libexec/webkit2gtk-4.0/WebKitPluginProcess"
	use nsplugin && pax-mark m "${ED}usr/libexec/webkit2gtk-4.0/WebKitPluginProcess"2
}
