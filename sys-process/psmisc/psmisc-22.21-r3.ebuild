# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils \
	autotools flag-o-matic #line added by muslx32 overlay

DESCRIPTION="A set of tools that use the proc filesystem"
HOMEPAGE="http://psmisc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~arm-linux ~x86-linux"
IUSE="ipv6 nls selinux X"

RDEPEND=">=sys-libs/ncurses-5.7-r7:0=
	nls? ( virtual/libintl )
	selinux? ( sys-libs/libselinux )"
DEPEND="${RDEPEND}
	>=sys-devel/libtool-2.2.6b
	nls? ( sys-devel/gettext )
	sys-devel/automake:1.14" #line added by muslx32 overlay

DOCS="AUTHORS ChangeLog NEWS README"

PATCHES=(
	"${FILESDIR}/${P}-fuser_typo_fix.patch"
	"${FILESDIR}/${P}-sysmacros.patch"
)

src_prepare() {
	epatch "${PATCHES[@]}"
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		epatch_user
		epatch "${FILESDIR}"/${PN}-22.21-r2-musl.patch
		sed -i "s|AC_FUNC_MALLOC|#AC_FUNC_MALLOC|g" configure.ac
		sed -i "s|AC_FUNC_REALLOC|#AC_FUNC_REALLOC|g" configure.ac
		eautoreconf
	fi
}

src_configure() {
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		append-cppflags -DX86_64
	fi
	#2 lines below were added by muslx32 overlay
	ac_cv_func_malloc_0_nonnull=yes \
	ac_cv_func_realloc_0_nonnull=yes \
	econf \
		$(use_enable selinux) \
		--disable-harden-flags \
		$(use_enable ipv6) \
		$(use_enable nls)
}

src_compile() {
	# peekfd is a fragile crap hack #330631
	nonfatal emake -C src peekfd || touch src/peekfd{.o,}
	emake
}

src_install() {
	default

	use X || rm -f "${ED}"/usr/bin/pstree.x11

	[[ -s ${ED}/usr/bin/peekfd ]] || rm -f "${ED}"/usr/bin/peekfd
	[[ -e ${ED}/usr/bin/peekfd ]] || rm -f "${ED}"/usr/share/man/man1/peekfd.1

	# fuser is needed by init.d scripts; use * wildcard for #458250
	dodir /bin
	mv "${ED}"/usr/bin/*fuser "${ED}"/bin || die
}
