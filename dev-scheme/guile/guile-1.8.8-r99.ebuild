# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=3
inherit eutils autotools flag-o-matic elisp-common toolchain-funcs

DESCRIPTION="Scheme interpreter"
HOMEPAGE="http://www.gnu.org/software/guile/"
SRC_URI="mirror://gnu/guile/${P}.tar.gz"

LICENSE="LGPL-2.1"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="networking +regex discouraged +deprecated emacs nls debug-freelist debug-malloc debug +threads"
RESTRICT="!regex? ( test )"

DEPEND="
	>=dev-libs/gmp-4.1
	>=sys-devel/libtool-1.5.6
	sys-devel/gettext
	emacs? ( virtual/emacs )"
RDEPEND="${DEPEND}"

# Guile seems to contain some slotting support, /usr/share/guile/ is slotted,
# but there are lots of collisions. Most in /usr/share/libguile. Therefore
# I'm slotting this in the same slot as guile-1.6* for now.
SLOT="12"
MAJOR="1.8"

src_prepare() {
	eautoreconf
	#epatch "${FILESDIR}/${P}-fix_guile-config.patch"
	#epatch "${FILESDIR}/${P}-gcc46.patch"
	#epatch "${FILESDIR}/${P}-os_dep.patch"
	#epatch "${FILESDIR}/${P}-makeinfo-5.patch"
	epatch "${FILESDIR}/${PN}-1.8.8-long_long_max.patch"
	epatch "${FILESDIR}"/${PN}-2.0.11-disable-automake.patch
	sed \
		-e "s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g" \
		-e "/AM_PROG_CC_STDC/d" \
		-i guile-readline/configure.in
}

src_configure() {
	# see bug #178499
	filter-flags -ftree-vectorize
	strip-flags
	filter-flags -O2 -O3 -O4 -Os -O1 -O0
	append-cflags -O2
	append-cxxflags -O2
	append-cppflags -I${S}/lib -I/usr/lib/gcc/${CHOST}/$(gcc-fullversion)/include-fixed/

	#will fail for me if posix is disabled or without modules -- hkBst
	econf \
		--disable-error-on-warning \
		--disable-static \
		--enable-posix \
		$(use_enable networking) \
		$(use_enable regex) \
		$(use deprecated || use_enable discouraged) \
		$(use_enable deprecated) \
		$(use_enable emacs elisp) \
		$(use_enable nls) \
		--disable-rpath \
		$(use_enable debug-freelist) \
		$(use_enable debug-malloc) \
		$(use_enable debug guile-debug) \
		$(use_with threads) \
		--with-modules \
		EMACS=no
}

src_compile()  {
	emake || die "make failed"

	# Above we have disabled the build system's Emacs support;
	# for USE=emacs we compile (and install) the files manually
	if use emacs; then
		cd emacs
		elisp-compile *.el || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"

	dodoc AUTHORS ChangeLog GUILE-VERSION HACKING NEWS README THANKS || die

	# texmacs needs this, closing bug #23493
	dodir /etc/env.d
	echo "GUILE_LOAD_PATH=\"${EPREFIX}/usr/share/guile/${MAJOR}\"" > "${ED}"/etc/env.d/50guile

	# necessary for registering slib, see bug 206896
	keepdir /usr/share/guile/site

	if use emacs; then
		elisp-install ${PN} emacs/*.{el,elc} || die
		elisp-site-file-install "${FILESDIR}/50${PN}-gentoo.el" || die
	fi
}

pkg_postinst() {
	[ "${EROOT}" == "/" ] && pkg_config
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}

pkg_config() {
	if has_version dev-scheme/slib; then
		einfo "Registering slib with guile"
		install_slib_for_guile
	fi
}

_pkg_prerm() {
	rm -f "${EROOT}"/usr/share/guile/site/slibcat
}
