# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.1"
#UCLIBC_VER="1.0"

inherit epatch toolchain

#KEYWORDS="~amd64 ~arm ~mips ~ppc ~x86"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	toolchain_src_prepare

	epatch "${FILESDIR}"/gcc-7.2.0-pr69728.patch

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		epatch "${FILESDIR}"/6.3.0/cpu_indicator.patch
		epatch "${FILESDIR}"/7.1.0/posix_memalign.patch
	fi

	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-1.patch
		if [[ ${CATEGORY} != cross-* ]] ; then
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-2a.patch
		else
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-2.patch
		fi
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-5.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-6.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-7.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-10.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-11.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-12.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-13.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-14.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-15.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-16.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-17.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-18.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-19.patch
		if [[ ${CATEGORY} != cross-* ]] ; then
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-20a.patch
		else
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-20.patch
		fi
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-21.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-22.patch
		epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-23.patch
		if [[ ${CATEGORY} != cross-* ]] ; then
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-24.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-25.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-26.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-27.patch #
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-28.patch #
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-29.patch #
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-30.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-31.patch #
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-32.patch #
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-34.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-36.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-37.patch
			#epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-38.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-39.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-40.patch
			#epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-41.patch
			#epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-42.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-43.patch
			epatch "${FILESDIR}"/gcc-7.3.0-libgcc-multilib-muslx32-44.patch
		fi
	fi
}
