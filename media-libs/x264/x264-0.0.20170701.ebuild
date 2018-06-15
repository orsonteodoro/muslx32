# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic multilib multilib-build multilib-minimal toolchain-funcs

DESCRIPTION="A free library for encoding X264/AVC streams"
HOMEPAGE="https://www.videolan.org/developers/x264.html"
if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.videolan.org/git/x264.git"
else
	inherit versionator
	MY_P="x264-snapshot-$(get_version_component_range 3)-2245"
	SRC_URI="https://download.videolan.org/pub/videolan/x264/snapshots/${MY_P}.tar.bz2"
	KEYWORDS="alpha amd64 ~arm ~arm64 ~hppa ia64 ~mips ~ppc ~ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
	S="${WORKDIR}/${MY_P}"
fi

SONAME="152"
SLOT="0/${SONAME}"

LICENSE="GPL-2"
IUSE="10bit altivec +interlaced opencl pic static-libs cpu_flags_x86_sse +threads"

ASM_DEP=">=dev-lang/nasm-2.13"
DEPEND="abi_x86_32? ( ${ASM_DEP} )
	abi_x86_64? ( ${ASM_DEP} )
	opencl? ( dev-lang/perl )"
RDEPEND="opencl? ( >=virtual/opencl-0-r3[${MULTILIB_USEDEP}] )"

DOCS=( AUTHORS doc/{ratecontrol,regression_test,standards,threads,vui}.txt )

src_prepare() {
	default
	multilib_copy_sources
}

multilib_src_configure() {
	if [[ "${CHOST_default}" =~ "muslx32" ]] ; then
		if [[ "${ABI}" == "amd64" ]] ; then
			export CC="${CHOST_default}-gcc ${CFLAGS_amd64}"
		elif [[ "${ABI}" == "x32" ]] ; then
			epatch "${FILESDIR}"/x264-0.0.20170701-x32-support.patch
			export CC="${CHOST_default}-gcc ${CFLAGS_x32}"
		elif [[ "${ABI}" == "x86" ]] ; then
			export CC="${CHOST_default}-gcc ${CFLAGS_x86}"
		fi
	fi
	export LD_LIBRARY_PATH=""

	echo "CC=${CC}"
	tc-export CC
	local asm_conf=""

	#if [[ ${ABI} == x86* ]] && { use pic || use !cpu_flags_x86_sse ; } || [[ ${ABI} == "x32" ]] || [[ ${CHOST} == armv5* ]] || [[ ${ABI} == ppc* ]] && { use !altivec ; }; then
	if [[ ${ABI} == x86* ]] && { use pic || use !cpu_flags_x86_sse ; } || [[ ${CHOST} == armv5* ]] || [[ ${ABI} == ppc* ]] && { use !altivec ; }; then
		asm_conf=" --disable-asm"
	fi

	"$(pwd)/configure" \
		--prefix="${EPREFIX}"/usr \
		--libdir="${EPREFIX}"/usr/$(get_libdir) \
		--disable-cli \
		--disable-avs \
		--disable-lavf \
		--disable-swscale \
		--disable-ffms \
		--disable-gpac \
		--enable-pic \
		--enable-shared \
		--host="${CHOST}" \
		$(usex 10bit "--bit-depth=10" "") \
		$(usex interlaced "" "--disable-interlaced") \
		$(usex opencl "" "--disable-opencl") \
		$(usex static-libs "--enable-static" "") \
		$(usex threads "" "--disable-thread") \
		${asm_conf} || die
}
