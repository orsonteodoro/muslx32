# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
AUTOTOOLS_AUTORECONF=1
WANT_AUTOMAKE=1.14

inherit autotools-multilib flag-o-matic

DESCRIPTION="General purpose crypto library based on the code used in GnuPG"
HOMEPAGE="http://www.gnupg.org/"
SRC_URI="mirror://gnupg/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1 MIT"
SLOT="0/20" # subslot = soname major version
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc static-libs"

RDEPEND=">=dev-libs/libgpg-error-1.12[${MULTILIB_USEDEP}]
	abi_x86_32? (
		!<=app-emulation/emul-linux-x86-baselibs-20131008-r19
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32]
	)"
DEPEND="${RDEPEND}
	doc? ( virtual/texi2dvi )"

DOCS=( AUTHORS ChangeLog NEWS README THANKS TODO )

PATCHES=(
	"${FILESDIR}"/${PN}-1.6.1-uscore.patch
	"${FILESDIR}"/${PN}-multilib-syspath.patch
)

src_prepare() {
	epatch "${PATCHES[@]}"
	#[[ "${CHOST}" =~ "muslx32" ]] && sed -i 's|__GNUC__ >= 3 &&||g' ./mpi/generic/mpi-asm-defs.h
	#[[ "${CHOST}" =~ "muslx32" ]] && sed -i 's|BYTES_PER_MPI_LIMB 8|BYTES_PER_MPI_LIMB 8|g' ./mpi/generic/mpi-asm-defs.h
}

MULTILIB_CHOST_TOOLS=(
	/usr/bin/libgcrypt-config
)

multilib_src_configure() {
	#strip-flags
	filter-flags -O0 -O1 -O2 -Os -O3 -O4
	append-cflags -O2
	append-cxxflags -O2
	if [[ ${CHOST} == *86*-solaris* ]] ; then
		# ASM code uses GNU ELF syntax, divide in particular, we need to
		# allow this via ASFLAGS, since we don't have a flag-o-matic
		# function for that, we'll have to abuse cflags for this
		append-cflags -Wa,--divide
	fi
	local myeconfargs=(
		--disable-dependency-tracking
		--enable-noexecstack #changed in x32
		--disable-O-flag-munging
		$(use_enable static-libs static)

		# disabled due to various applications requiring privileges
		# after libgcrypt drops them (bug #468616)
		--without-capabilities

		# http://trac.videolan.org/vlc/ticket/620
		# causes bus-errors on sparc64-solaris
		$([[ ${CHOST} == *86*-darwin* ]] && echo "--disable-asm")
		$([[ ${CHOST} == sparcv9-*-solaris* ]] && echo "--disable-asm")
	)
	autotools-utils_src_configure
}

multilib_src_compile() {
	emake
	multilib_is_native_abi && use doc && VARTEXFONTS="${T}/fonts" emake -C doc gcrypt.pdf
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	multilib_is_native_abi && use doc && dodoc doc/gcrypt.pdf
}
