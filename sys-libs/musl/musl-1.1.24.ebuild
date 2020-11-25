# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils flag-o-matic multilib-minimal toolchain-funcs
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://git.musl-libc.org/musl"
	inherit git-r3
	SRC_URI="
	https://dev.gentoo.org/~blueness/musl-misc/getconf.c
	https://dev.gentoo.org/~blueness/musl-misc/getent.c
	https://dev.gentoo.org/~blueness/musl-misc/iconv.c"
	KEYWORDS=""
else
	SRC_URI="http://www.musl-libc.org/releases/${P}.tar.gz
	https://dev.gentoo.org/~blueness/musl-misc/getconf.c
	https://dev.gentoo.org/~blueness/musl-misc/getent.c
	https://dev.gentoo.org/~blueness/musl-misc/iconv.c"
	KEYWORDS="-* amd64 arm arm64 ~mips ppc ppc64 x86"
fi

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

# current sub
abi_to_host() {
	local abi="$1"
	if [[ "${abi}" == "amd64" ]] ; then
		echo "x86_64-pc-linux-musl"
	elif [[ "${abi}" == "x86" ]] ; then
		echo "i686-pc-linux-musl"
	elif [[ "${abi}" == "x32" ]] ; then
		echo "x86_64-pc-linux-muslx32"
	else
		die "Unsupported ${abi}.  Please expand list."
	fi
}

multilib_cflags() {
	if [[ "${ABI}" == "amd64" ]] ; then
		echo "${CFLAGS_amd64} --sysroot=/usr/x86_64-pc-linux-musl/usr/lib"
	elif [[ "${ABI}" == "x86" ]] ; then
		echo "${CFLAGS_x86} --sysroot=/usr/i686-pc-linux-musl/usr/lib"
	elif [[ "${ABI}" == "x32" ]] ; then
		echo "${CFLAGS_x32} --sysroot=/usr/x86_64-pc-linux-muslx32/usr/lib"
	else
		die "Unsupported ${ABI}.  Please expand list."
	fi
}

multilib_ldflags() {
	if [[ "${ABI}" == "amd64" ]] ; then
		echo "${LDFLAGS_amd64}"
	elif [[ "${ABI}" == "x86" ]] ; then
		echo "${LDFLAGS_x86}"
	elif [[ "${ABI}" == "x32" ]] ; then
		echo "${LDFLAGS_x32}"
	else
		die "Unsupported ${ABI}.  Please expand list."
	fi
}

ctarget_libdir() {
        if [[ "${CTARGET}" == "x86_64-pc-linux-musl" ]] ; then
                echo "lib64"
        elif [[ "${CTARGET}" == "i686-pc-linux-musl" ]] ; then
                echo "lib32"
        elif [[ "${CTARGET}" == "x86_64-pc-linux-muslx32" ]] ; then
                echo "libx32"
        else
                die "Unsupported ${CTARGET}.  Please expand list."
        fi
}

host_libdir() {
	local host="$1"
        if [[ "${host}" == "x86_64-pc-linux-musl" ]] ; then
                echo "lib64"
        elif [[ "${host}" == "i686-pc-linux-musl" ]] ; then
                echo "lib32"
        elif [[ "${host}" == "x86_64-pc-linux-muslx32" ]] ; then
                echo "libx32"
        else
                die "Unsupported ${host}.  Please expand list."
        fi
}

abi_libdir() {
	local host="$1"
        if [[ "${host}" == "amd64" ]] ; then
                echo "lib64"
        elif [[ "${host}" == "x86" ]] ; then
                echo "lib32"
        elif [[ "${host}" == "x32" ]] ; then
                echo "libx32"
        else
                die "Unsupported ${host}.  Please expand list."
        fi
}

abi_native() {
	local abi="$1"
        if [[ "${abi}" == "amd64" ]] ; then
                echo "x86_64"
        elif [[ "${abi}" == "x86" ]] ; then
                echo "i386"
        elif [[ "${abi}" == "x32" ]] ; then
                echo "x32"
        else
                die "Unsupported ${host}.  Please expand list."
        fi
}

DESCRIPTION="Light, fast and simple C library focused on standards-conformance and safety"
HOMEPAGE="http://www.musl-libc.org/"
LICENSE="MIT LGPL-2 GPL-2"
SLOT="0"
IUSE="headers-only"

#QA_SONAME="/usr/lib/libc.so"
#QA_DT_NEEDED="/usr/lib/libc.so"
ARCHES=

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

just_headers() {
	use headers-only && is_crosscompile
}

pkg_setup() {
	if [ ${CTARGET} == ${CHOST} ] ; then
		case ${CHOST} in
		*-musl*) ;;
		*) die "Use sys-devel/crossdev to build a musl toolchain" ;;
		esac
	fi

	# fix for #667126, copied from glibc ebuild
	# make sure host make.conf doesn't pollute us
	if is_crosscompile || tc-is-cross-compiler ; then
		CHOST=${CTARGET} strip-unsupported-flags
	fi
}

src_prepare() {
	default
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		eapply "${FILESDIR}"/musl-1.1.15-gdb-ptrace.patch # for gdb on x32
		eapply "${FILESDIR}"/musl-9999-timex-x32.patch # for chrony
		eapply "${FILESDIR}"/musl-1.2.1-add_libssp_nonshared.patch # for multilib gcc on i686
	fi
	eapply_user
	multilib_copy_sources
}

multilib_src_configure() {
	export CTARGET2=$(abi_to_host ${ABI})
	einfo "Multilib sub ABI: CTARGET2=${CTARGET2}"
	einfo "Default ABI: CTARGET=${CTARGET}"
	tc-getCC ${CTARGET}
	just_headers && export CC=true

	libdir="lib"
	if ! is_crosscompile ; then
		libdir=$(abi_libdir ${ABI})
	fi

	export CROSS_COMPILE="${CTARGET}-"
	local sysroot
	is_crosscompile && sysroot=/usr/${CTARGET2}
	./configure \
		--target=${CTARGET2} \
		--prefix=${sysroot}/usr \
		--syslibdir=${sysroot}/${libdir} \
		--disable-gcc-wrapper || die

	export ARCHES="${ARCHES} $(abi_native ${ABI})"
	einfo "ARCHES=${ARCHES}"
}

multilib_src_compile() {
	emake obj/include/bits/alltypes.h
	just_headers && return 0

	emake
	if [[ ${CATEGORY} != cross-* ]] ; then
		$(tc-getCC) ${CFLAGS} "${DISTDIR}"/getconf.c -o "${T}"/getconf || die
		$(tc-getCC) ${CFLAGS} "${DISTDIR}"/getent.c -o "${T}"/getent || die
		$(tc-getCC) ${CFLAGS} "${DISTDIR}"/iconv.c -o "${T}"/iconv || die
	fi
}

multilib_src_install() {
	export CTARGET2=$(abi_to_host ${ABI})
	einfo "CTARGET2=${CTARGET2}"
	einfo "CTARGET=${CTARGET}"
	local target="install"
	just_headers && target="install-headers"
	emake DESTDIR="${D}" ${target}
	just_headers && return 0

	libdir="lib"
	if ! is_crosscompile ; then
		libdir=$(abi_libdir ${ABI})
	fi
	einfo "libdir=${libdir}"

	# musl provides ldd via a sym link to its ld.so
	local sysroot
	is_crosscompile && sysroot=/usr/${CTARGET2}
	local default_libdir=${libdir}
	local ldso=$(basename "${D}"${sysroot}/${libdir}/ld-musl-*)
	dosym ../${libdir}/${ldso} ${sysroot}/usr/bin/ldd

	# force relative
	rm "${D}"/usr/${CTARGET2}/usr/lib/${ldso} || die
	dosym libc.so /usr/${CTARGET2}/usr/lib/${ldso}

	if [[ "${ABI}" == "${DEFAULT_ABI}" ]] ; then
		# force relative
		rm "${D}"/usr/${CTARGET}/lib/${ldso} || die
		dosym ../usr/lib/libc.so /usr/${CTARGET}/${default_libdir}/${ldso}
	fi

	if is_crosscompile ; then
		einfo "default abi"

		_libdir=$(abi_libdir ${ABI})
		into /
		dodir /usr/${CTARGET}/usr

		if [[ "${ABI}" == "${DEFAULT_ABI}" ]] ; then
			einfo "is default_abi"
			into /

			mv "${D}"/usr/${CTARGET}/usr/lib "${D}"/usr/${CTARGET}/usr/${_libdir} || die
			[[ -d "${D}"/usr/${CTARGET}/usr/${_libdir} ]] || die

			mv "${D}"/usr/${CTARGET}/lib "${D}"/usr/${CTARGET}/${_libdir} || die
			[[ -d "${D}"/usr/${CTARGET}/${_libdir} ]] || die

			dosym ${_libdir} /usr/${CTARGET}/lib
			dosym ${_libdir} /usr/${CTARGET}/usr/lib
		else
			einfo "not default_abi"

			cp -a "${D}"/usr/${CTARGET2} "${D}"/usr/${CTARGET}/usr/ || die
			[[ -d "${D}"/usr/${CTARGET}/usr/${CTARGET2} ]] || die

			dosym ../usr/${CTARGET2}/usr/lib/libc.so /usr/${CTARGET}/${_libdir}/${ldso}
			rm ${D}/usr/${CTARGET}/usr/${CTARGET2}/lib/${ldso} || die
			dosym ../usr/lib/libc.so /usr/${CTARGET}/usr/${CTARGET2}/lib/${ldso}
		fi
	fi

	# force creation
	dodir /usr/$(abi_libdir ${ABI})
	dodir /usr/local/$(abi_libdir ${ABI})

	if [[ ${CATEGORY} != cross-* && "${ABI}" == "${DEFAULT_ABI}" ]] ; then
		# Fish out of config:
		#   ARCH = ...
		#   SUBARCH = ...
		# and print $(ARCH)$(SUBARCH).
		local arch=$(awk '{ k[$1] = $3 } END { printf("%s%s", k["ARCH"], k["SUBARCH"]); }' config.mak)
		[[ -e "${D}"/$(abi_libdir ${ABI})/ld-musl-${arch}.so.1 ]] || die
		cp "${FILESDIR}"/ldconfig.in.multilib "${T}" || die
		local native=$(abi_native ${ABI})
		sed -e "s|@@ARCH@@|${arch}|" -e "s|@@ARCHES@@|${ARCHES}|" "${T}"/ldconfig.in.multilib > "${T}"/ldconfig || die
		into /
		dosbin "${T}"/ldconfig
		into /usr
		dobin "${T}"/getconf
		dobin "${T}"/getent
		dobin "${T}"/iconv
		echo 'LDPATH="include ld.so.conf.d/*.conf"' > "${T}"/00musl || die
		doenvd "${T}"/00musl
	fi
}

pkg_postinst() {
	is_crosscompile && return 0

	[ "${ROOT}" != "/" ] && return 0

	ldconfig || die
}
