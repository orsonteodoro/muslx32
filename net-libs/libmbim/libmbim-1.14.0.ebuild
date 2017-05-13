# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit multilib flag-o-matic

DESCRIPTION="Mobile Broadband Interface Model (MBIM) modem protocol helper library"
HOMEPAGE="https://cgit.freedesktop.org/libmbim/"
SRC_URI="https://www.freedesktop.org/software/${PN}/${P}.tar.xz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~mips ppc ppc64 x86"
IUSE="static-libs udev"

RDEPEND=">=dev-libs/glib-2.32:2
	udev? ( virtual/libgudev:= )"
DEPEND="${RDEPEND}
	dev-util/gtk-doc-am
	virtual/pkgconfig"

src_prepare() {
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		epatch "${FILESDIR}"/${PN}-1.14.0-canonicalize_file_name-musl.patch
	fi
	default
}

src_configure() {
	econf \
		--disable-more-warnings \
		--disable-gtk-doc \
		$(use_with udev) \
		$(use_enable static{-libs,})
}

src_install() {
	default
	use static-libs || rm -f "${ED}/usr/$(get_libdir)/${PN}-glib.la"
}
