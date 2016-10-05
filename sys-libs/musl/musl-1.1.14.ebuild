# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils flag-o-matic multilib toolchain-funcs
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://git.musl-libc.org/musl"
	inherit git-r3
fi

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

DESCRIPTION="Light, fast and simple C library focused on standards-conformance and safety"
HOMEPAGE="http://www.musl-libc.org/"
if [[ ${PV} != "9999" ]] ; then
	PATCH_VER=""
	SRC_URI="http://www.musl-libc.org/releases/${P}.tar.gz"
	KEYWORDS="-* amd64 arm ~mips ppc x86"
fi

LICENSE="MIT LGPL-2 GPL-2"
SLOT="0"
IUSE="crosscompile_opts_headers-only"

RDEPEND="!sys-apps/getent"

QA_SONAME="/usr/lib/libc.so"
QA_DT_NEEDED="/usr/lib/libc.so"

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

just_headers() {
	use crosscompile_opts_headers-only && is_crosscompile
}

musl_endian() {
	# XXX: this wont work for bi-endian, but we dont have any
	touch "${T}"/endian.s || die
	$(tc-getAS ${CTARGET}) "${T}"/endian.s -o "${T}"/endian.o
	case $(file "${T}"/endian.o) in
		*" MSB "*) echo "";;
		*" LSB "*) echo "el";;
		*)         echo "nfc";; # We shouldn't be here
	esac
}

pkg_setup() {
	if [ ${CTARGET} == ${CHOST} ] ; then
		case ${CHOST} in
		*-musl*) ;;
		*) die "Use sys-devel/crossdev to build a musl toolchain" ;;
		esac
	fi
}

src_prepare() {
	epatch_user
	epatch "${FILESDIR}"/musl-1.1.14-gdb-ptrace.patch
	epatch "${FILESDIR}"/musl-9999-x32-relative64-1.patch
	epatch "${FILESDIR}"/musl-1.1.14-x32-sendmsg.patch
	epatch "${FILESDIR}"/musl-9999-pthread_setname_np.patch #for firefox 49.x
	epatch "${FILESDIR}"/musl-9999-timex-x32.patch #for chrony
}

src_configure() {
	tc-getCC ${CTARGET}
	just_headers && export CC=true

	local sysroot
	is_crosscompile && sysroot=/usr/${CTARGET}
	./configure \
		--target=${CTARGET} \
		--prefix=${sysroot}/usr \
		--syslibdir=${sysroot}/lib \
		--disable-gcc-wrapper
}

src_compile() {
	emake obj/include/bits/alltypes.h
	just_headers && return 0

	emake
}

src_install() {
	local target="install"
	just_headers && target="install-headers"
	emake DESTDIR="${D}" ${target}
	just_headers && return 0

	# musl provides ldd via a sym link to its ld.so
	local sysroot
	is_crosscompile && sysroot=/usr/${CTARGET}
	local ldso=$(basename "${D}"${sysroot}/lib/ld-musl-*)
	dosym ${sysroot}/lib/${ldso} ${sysroot}/usr/bin/ldd

	if [[ ${CATEGORY} != cross-* ]] ; then
		local target=$(tc-arch) arch
		local endian=$(musl_endian)
		case ${target} in
			amd64) arch="x86_64";;
			arm)   arch="armhf";; # We only have hardfloat right now
			mips)  arch="mips${endian}";;
			ppc)   arch="powerpc";;
			x86)   arch="i386";;
		esac
		cp "${FILESDIR}"/ldconfig.in "${T}" || die
		local myarch
		if [[ "${CHOST}" =~ "muslx32" ]]; then
			myarch="x32"
		else
			myarch="${arch}"
		fi
		sed -e "s|@@ARCH@@|${myarch}|" "${T}"/ldconfig.in > "${T}"/ldconfig || die
		into /
		dosbin "${T}"/ldconfig
		into /usr
		dobin "${FILESDIR}"/getent
		echo 'LDPATH="include ld.so.conf.d/*.conf"' > "${T}"/00musl || die
		doenvd "${T}"/00musl || die
	fi
}

pkg_postinst() {
	is_crosscompile && return 0

	[ "${ROOT}" != "/" ] && return 0

	ldconfig
	# reload init ...
	/sbin/telinit U 2>/dev/null
}
