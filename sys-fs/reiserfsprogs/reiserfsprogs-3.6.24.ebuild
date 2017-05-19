# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit flag-o-matic \
	autotools eutils #added my muslx32 overlay

DESCRIPTION="Reiserfs Utilities"
HOMEPAGE="https://www.kernel.org/pub/linux/utils/fs/reiserfs/"
SRC_URI="mirror://kernel/linux/utils/fs/reiserfs/${P}.tar.xz
	mirror://kernel/linux/kernel/people/jeffm/${PN}/v${PV}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 -sparc x86 ~amd64-linux ~x86-linux"
IUSE=""
DEPEND="elibc_musl? ( sys-libs/musl-obstack )"

src_prepare() { #function added by muslx32 overlay
	default
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		#from void linux
		epatch "${FILESDIR}"/musl-__compar_fn_t.patch
		epatch "${FILESDIR}"/musl-long_long_min_max.patch
		epatch "${FILESDIR}"/musl-prints.patch
		epatch "${FILESDIR}"/${PN}-3.6.24-install-exec-hook-musl.patch
		eautoreconf
	fi
}

src_configure() {
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		filter-flags -Wl,--as-needed
		append-ldflags -lobstack
	fi
	append-flags -std=gnu89 #427300
	econf --prefix="${EPREFIX}/"
}
