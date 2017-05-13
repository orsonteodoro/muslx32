# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils gnome2-utils vcs-snapshot xdg

DESCRIPTION="Qt password manager compatible with its Win32 and Pocket PC versions"
HOMEPAGE="http://www.keepassx.org/"
SRC_URI="https://www.keepassx.org/releases/${PV}/${P}.tar.gz"

LICENSE="|| ( GPL-2 GPL-3 ) BSD GPL-2 LGPL-2.1 LGPL-3+ CC0-1.0 public-domain || ( LGPL-2.1 GPL-3 )"
SLOT="0"
KEYWORDS="amd64 ~arm ppc x86 ~amd64-linux ~x86-linux"
IUSE="test"

DEPEND="
	dev-libs/libgcrypt:0=
	dev-qt/qtcore:4
	dev-qt/qtgui:4
	dev-qt/qttest:4
	sys-libs/zlib
	x11-libs/libX11
	x11-libs/libXtst
"
RDEPEND="${DEPEND}"

DOCS=(CHANGELOG)

src_prepare() {
	if [[ "${CHOST}" =~ "muslx32" ]]; then
		#sed -i "s|-fstack-protector --param=ssp-buffer-size=4||g" ./CMakeLists.txt
		epatch "${FILESDIR}"/${PN}-2.0.2-musl.patch
	fi
	xdg_src_prepare
	cmake-utils_src_prepare
}

src_configure() {
	if [[ "${CHOST}" =~ "muslx32" ]]; then
		append-cflags -D_GNU_SOURCE
		append-cxxflags -D_GNU_SOURCE
	fi
	local mycmakeargs=(
		-DWITH_TESTS="$(usex test)"
	)
	cmake-utils_src_configure
}

pkg_preinst() {
	gnome2_icon_savelist
	xdg_pkg_preinst
}
pkg_postinst() {
	gnome2_icon_cache_update
	xdg_pkg_postinst
}

pkg_postrm() {
	gnome2_icon_cache_update
	xdg_pkg_postrm
}
