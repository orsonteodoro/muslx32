# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
VIRTUALX_REQUIRED="pgo"
WANT_AUTOCONF="2.1"
MOZ_ESR=1

# This list can be updated with scripts/get_langs.sh from the mozilla overlay
MOZ_LANGS=( ach af an ar as ast az bg bn-BD bn-IN br bs ca cak cs cy da de dsb
el en en-GB en-US en-ZA eo es-AR es-CL es-ES es-MX et eu fa ff fi fr fy-NL ga-IE
gd gl gn gu-IN he hi-IN hr hsb hu hy-AM id is it ja ka kab kk km kn ko lij lt lv
mai mk ml mr ms nb-NO nl nn-NO or pa-IN pl pt-BR pt-PT rm ro ru si sk sl son sq
sr sv-SE ta te th tr uk uz vi xh zh-CN zh-TW )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_alpha/a}" # Handle alpha for SRC_URI
MOZ_PV="${MOZ_PV/_beta/b}" # Handle beta for SRC_URI
MOZ_PV="${MOZ_PV/_rc/rc}" # Handle rc for SRC_URI

if [[ ${MOZ_ESR} == 1 ]]; then
	# ESR releases have slightly different version numbers
	MOZ_PV="${MOZ_PV}esr"
fi

# Patch version
PATCH="${PN}-52.0-patches-08"
MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"

MOZCONFIG_OPTIONAL_GTK2ONLY=1
MOZCONFIG_OPTIONAL_WIFI=1
MOZCONFIG_OPTIONAL_JIT="enabled" #readded by muslx32 overlay

inherit check-reqs flag-o-matic toolchain-funcs eutils gnome2-utils mozconfig-v6.52 pax-utils fdo-mime autotools virtualx mozlinguas-v2

DESCRIPTION="Firefox Web Browser"
HOMEPAGE="http://www.mozilla.com/firefox"

KEYWORDS="~alpha amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist +gmp-autoupdate hardened hwaccel jack pgo rust selinux test"
IUSE+=" experimental jit"
REQUIRED_USE="elibc_musl? ( abi_x86_x32? ( system-libvpx !jit )  ) !experimental" #fix experimental patches before removing
RESTRICT="!bindist? ( bindist )"

PATCH_URIS=( https://dev.gentoo.org/~{anarchy,axs,polynomial-c}/mozilla/patchsets/${PATCH}.tar.xz )
SRC_URI="${SRC_URI}
	${MOZ_HTTP_URI}/${MOZ_PV}/source/firefox-${MOZ_PV}.source.tar.xz
	${PATCH_URIS[@]}"

ASM_DEPEND=">=dev-lang/yasm-1.1"

RDEPEND="
	jack? ( virtual/jack )
	>=dev-libs/nss-3.28.3
	>=dev-libs/nspr-4.13.1
	selinux? ( sec-policy/selinux-mozilla )"

DEPEND="${RDEPEND}
	pgo? ( >=sys-devel/gcc-4.5 )
	rust? ( dev-lang/rust )
	amd64? ( ${ASM_DEPEND} virtual/opengl )
	x86? ( ${ASM_DEPEND} virtual/opengl )"

S="${WORKDIR}/firefox-${MOZ_PV}"

QA_PRESTRIPPED="usr/lib*/${PN}/firefox"

BUILD_OBJ_DIR="${S}/ff"

# allow GMP_PLUGIN_LIST to be set in an eclass or
# overridden in the enviromnent (advanced hackers only)
if [[ -z $GMP_PLUGIN_LIST ]]; then
	GMP_PLUGIN_LIST=( gmp-gmpopenh264 gmp-widevinecdm )
fi

pkg_setup() {
        if [[ "${CHOST}" =~ "muslx32" ]] ; then
                ewarn "this ebuild doesn't work for muslx32.  it is left for ebuild developers to work on it."
		ewarn "reason: segfaults.  fix javascript bug.  fix 49.0 before fixing 52.1."
		if [[ "${MUSLX32_OVERLAY_DEVELOPER}" != "1" ]] ; then
			eerror "add MUSLX32_OVERLAY_DEVELOPER=1 to /etc/portage/make.conf to continue emerging broken package."
			die
		fi
#Thread 1 "firefox" received signal SIGSEGV, Segmentation fault.
#0xe8b65d38 in PseudoStack::push (this=0xffffcfff, aName=0xeede4ed0 "Startup::XRE_Main", aCategory=js::ProfileEntry::Category::OTHER, aStackAddress=0xffffc000, aCopy=false, line=4560)
#    at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/ff/dist/include/PseudoStack.h:263
#263	    if (size_t(mStackPointer) >= mozilla::ArrayLength(mStack)) {
#(gdb) bt
#0  0xe8b65d38 in PseudoStack::push (this=0xffffcfff, aName=0xeede4ed0 "Startup::XRE_Main", aCategory=js::ProfileEntry::Category::OTHER, aStackAddress=0xffffc000, aCopy=false, line=4560)
#    at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/ff/dist/include/PseudoStack.h:263
#1  0xe8b6605b in mozilla_sampler_call_enter (aInfo=0xeede4ed0 "Startup::XRE_Main", aCategory=js::ProfileEntry::Category::OTHER, aFrameAddress=0xffffc000, aCopy=false, line=4560)
#    at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/ff/dist/include/GeckoProfilerImpl.h:489
#2  0xe8b65f9a in mozilla::SamplerStackFrameRAII::SamplerStackFrameRAII (this=0xffffc000, aInfo=0xeede4ed0 "Startup::XRE_Main", aCategory=js::ProfileEntry::Category::OTHER, line=4560)
#    at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/ff/dist/include/GeckoProfilerImpl.h:422
#3  0xecfd9481 in XREMain::XRE_main (this=0xffffc060, argc=1, argv=0xffffd354, aAppData=0xffffd1f0) at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/toolkit/xre/nsAppRunner.cpp:4559
#4  0xecfd9a3f in XRE_main (argc=1, argv=0xffffd354, aAppData=0xffffd1f0, aFlags=0) at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/toolkit/xre/nsAppRunner.cpp:4712
#5  0x56558f1f in do_main (argc=1, argv=0xffffd354, envp=0xffffd35c, xreDirectory=0x56795890) at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/browser/app/nsBrowserApp.cpp:282
#6  0x5655928f in main (argc=1, argv=0xffffd354, envp=0xffffd35c) at /var/tmp/portage/www-client/firefox-52.1.0-r1/work/firefox-52.1.0esr/browser/app/nsBrowserApp.cpp:415
        fi
	moz_pkgsetup

	# Avoid PGO profiling problems due to enviroment leakage
	# These should *always* be cleaned up anyway
	unset DBUS_SESSION_BUS_ADDRESS \
		DISPLAY \
		ORBIT_SOCKETDIR \
		SESSION_MANAGER \
		XDG_SESSION_COOKIE \
		XAUTHORITY

	if ! use bindist; then
		einfo
		elog "You are enabling official branding. You may not redistribute this build"
		elog "to any users on your network or the internet. Doing so puts yourself into"
		elog "a legal problem with Mozilla Foundation"
		elog "You can disable it by emerging ${PN} _with_ the bindist USE-flag"
	fi

	if use pgo; then
		einfo
		ewarn "You will do a double build for profile guided optimization."
		ewarn "This will result in your build taking at least twice as long as before."
	fi

	if use rust; then
		einfo
		ewarn "This is very experimental, should only be used by those developing firefox."
	fi
}

pkg_pretend() {
	# Ensure we have enough disk space to compile
	if use pgo || use debug || use test ; then
		CHECKREQS_DISK_BUILD="8G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi
	check-reqs_pkg_setup
}

src_unpack() {
	unpack ${A}

	# Unpack language packs
	mozlinguas_src_unpack
}

src_prepare() {
	# Apply our patches
	eapply "${WORKDIR}/firefox"
	eapply "${FILESDIR}"/musl_drop_hunspell_alloc_hooks.patch

	#fix http2/http1 bug already applied

	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		if [[ "${CHOST}" =~ "musl" ]]; then
			sed -i "s|#include <sys/cdefs.h>|#include <sys/types.h>|g" ./security/sandbox/chromium/sandbox/linux/system_headers/linux_seccomp.h || die "musl patch failed"
			cp "${FILESDIR}"/stab.h "${S}"/toolkit/crashreporter/google-breakpad/src/ || die "failed to copy stab.h"
			epatch "${FILESDIR}"/${PN}-38.8.0-blocksize-musl.patch
			epatch "${FILESDIR}"/${PN}-38.8.0-updater.patch
		fi
		if use abi_x86_x32; then
			append-cppflags -DOS_LINUX=1 #1
			epatch "${FILESDIR}"/${PN}-38.8.0-dont-use-amd64-ycbcr-on-x32.patch #2
			epatch "${FILESDIR}"/${PN}-38.8.0-fix-non-__lp64__-for-x32.patch
			epatch "${FILESDIR}"/${PN}-52.1.0-disable-breakpad-on-x32.patch ##
			#epatch "${FILESDIR}"/${PN}-47.0.1-disable-crashreporter.patch
			epatch "${FILESDIR}"/${PN}-49.0-no-jit-on-x32.patch ##
			if use system-jpeg ; then
				epatch "${FILESDIR}"/${PN}-49.0.0-enable-jpegturbo-optimizations-on-x32.patch
			else
				epatch "${FILESDIR}"/${PN}-49.0.0-disable-jpegturbo-optimizations-on-x32.patch
			fi
			epatch "${FILESDIR}"/${PN}-45.2.0-sysdef.patch
			epatch "${FILESDIR}"/${PN}-49.0-linux_syscall_support_h-x32.patch #checking ##
			epatch "${FILESDIR}"/${PN}-45.2.0-stat-x32.patch #test
			epatch "${FILESDIR}"/${PN}-49.0-asflags-elfx32.patch # ###
			sed -i 's|-f elf64|-f elfx32|' ./old-configure.in || die "sed failed for elfx32 (1)"
			sed -i 's|-f elf64|-f elfx32|' ./old-configure || die "sed failed for elfx32 (2)"
			epatch "${FILESDIR}"/${PN}-52.1.0-x32-structs64-1.patch #test ##
			#epatch "${FILESDIR}"/${PN}-47.0.1-fstat-missing.patch test
			#epatch "${FILESDIR}"/${PN}-47.0.1-stat64-x32.patch #test

			if ! use experimental ; then
				#disable all simd
				##
				sed -i 's|--enable-asm --enable-yasm|--disable-asm --disable-yasm|g' ./media/ffvpx/config_unix64.h || die "sed failed disabling asm for ffvpx" #
				sed -i 's|HAVE_YASM 1|HAVE_YASM 0|g' ./media/ffvpx/config_unix64.h || die "sed failed disabling yasm for ffvpx" #
				sed -i 's|HAVE_INLINE_ASM 1|HAVE_INLINE_ASM 0|g' ./media/ffvpx/config_unix64.h || die "sed failed disabling inline asm for ffvpx" #
				sed -i 's|HAVE_YASM 1|HAVE_YASM 0|g' ./media/ffvpx/config_unix64.asm || die "sed failed disabling yasm for ffvpx" #
				sed -i 's|HAVE_INLINE_ASM 1|HAVE_INLINE_ASM 0|g' ./media/ffvpx/config_unix64.asm || die "sed failed disabling inline asm for ffvpx" #

				##
				sed -i 's|--enable-asm --enable-yasm|--disable-asm --disable-yasm|g' ./media/ffvpx/config_unix32.h || die "sed failed disabling asm for ffvpx" #
				sed -i 's|HAVE_YASM 1|HAVE_YASM 0|g' ./media/ffvpx/config_unix32.h || die "sed failed disabling yasm for ffvpx" #
				sed -i 's|HAVE_INLINE_ASM 1|HAVE_INLINE_ASM 0|g' ./media/ffvpx/config_unix32.h || die "sed failed disabling inline asm for ffvpx" #

				epatch "${FILESDIR}"/${PN}-47.0.1-ffvpx-moz_build.patch #
				sed -i 's|#ifdef cpuid|#if 0|g' ./media/ffvpx/libavutil/x86/cpu.c #
			else
				#enable all simd
				#simd fixes provided by ebuilds
				pushd media/ffvpx
				epatch "${FILESDIR}"/02-14-x32-inline-asm-fix-asm.h.patch
				epatch "${FILESDIR}"/03-14-x32-inline-asm-fix-cpudetection.patch
				epatch "${FILESDIR}"/14a-14-x32-yasm-videodsp.asm-fix-access-to-parameters-passed-on-stack.patch
				epatch "${FILESDIR}"/14b-14-x32-yasm-videodsp.asm-fix-access-to-parameters-passed-on-stack.patch
				popd
				epatch "${FILESDIR}"/firefox-49.0-ffvpx-x32-cabac.patch
				sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|%define ARCH_X86_64 1\n|%define ARCH_X86_64 1\n%define ARCH_X86_64_X64 0\n%define ARCH_X86_64_X32 1\n|g' ./media/ffvpx/config.asm
				sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|%define ARCH_X86_64 1\n|%define ARCH_X86_64 1\n%define ARCH_X86_64_X64 0\n%define ARCH_X86_64_X32 1\n|g' ./media/ffvpx/config_unix64.asm
		                sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|#define ARCH_X86_64 1\n|#define ARCH_X86_64 1\n#define ARCH_X86_64_X64 0\n#define ARCH_X86_64_X32 1\n|g' ./media/ffvpx/config_unix64.h
				sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|#elif defined\(XP_UNIX\)\n#if defined\(HAVE_64BIT_BUILD\)|#elif defined(XP_UNIX)\n#if defined(HAVE_64BIT_BUILD) \|\| (defined(__x86_64__) \&\& defined(__ILP32__))|g' ./media/ffvpx/config.h

				pushd media/libav
				epatch "${FILESDIR}"/02-14-x32-inline-asm-fix-asm.h.patch
				epatch "${FILESDIR}"/03-14-x32-inline-asm-fix-cpudetection.patch
				epatch "${FILESDIR}"/07-14-x32-yasm-fft.asm-fix-pointer-access.patch
				epatch "${FILESDIR}"/06-14-x32-yasm-x86inc-add-ptrsize-and-p-suffix.patch
				popd
				sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|%define ARCH_X86_32 0\n%define ARCH_X86_64 1\n|%define ARCH_X86_32 0\n%define ARCH_X86_64 1\n%define ARCH_X86_64_X64 0\n%define ARCH_X86_64_X32 1\n|g' ./media/libav/config_common.asm
				sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|#define ARCH_X86_32 0\n#define ARCH_X86_64 1\n|#define ARCH_X86_32 0\n#define ARCH_X86_64 1\n#define ARCH_X86_64_X64 0\n#define ARCH_X86_64_X32 1\n|g' ./media/libav/config_common.h

				epatch "${FILESDIR}"/firefox-49.0-libvpx-libyuv-x32.patch
				sed -i -r -e ':a' -e 'N' -e '$!ba' -e 's|#define ARCH_X86_64 1\n|#define ARCH_X86_64 1\n#define ARCH_X86_64_X64 0\n#define ARCH_X86_64_X32 1\n|g' ./media/libvpx/vpx_config_x86_64-linux-gcc.h
			fi

	                ##epatch "${FILESDIR}"/${PN}-49.0-ffvpx-x32-1.patch ##
	                ##epatch "${FILESDIR}"/${PN}-49.0-ffvpx-x32-2.patch ##
			epatch "${FILESDIR}"/${PN}-47.0.1-xpcom-x32.patch
			epatch "${FILESDIR}"/${PN}-52.1.0-disable-hw-intel-aes.patch
			#epatch "${FILESDIR}"/${PN}-49.0-pthread_setname_np-musl.patch

			if use experimental ; then
				epatch "${FILESDIR}"/firefox-49.0-x32-libjpeg-1.patch
				epatch "${FILESDIR}"/firefox-49.0-x32-libjpeg-2.patch
				pushd media/libjpeg
				epatch "${FILESDIR}"/firefox-49.0-x32-libjpeg-3.patch
				epatch "${FILESDIR}"/firefox-49.0-x32-libjpeg-4.patch
				popd
			fi
			epatch "${FILESDIR}"/${PN}-45.4.0-event-size-symbol-rename.patch #for >=libevent-2.1.8
			#epatch "${FILESDIR}"/${PN}-52.1.0-disable-64bit-check.patch
			sed -i -e "s|'HAVE_64BIT_BUILD', have_64_bit|'HAVE_64BIT_BUILD', False|g" build/moz.configure/init.configure #fix unboxing types... it should be NUNBOX
			sed -i -r -e 's|sizeof\(void \*\) == 8|sizeof(void \*) == 4|g' build/moz.configure/toolchain.configure #kill warning
			epatch "${FILESDIR}"/${PN}-52.1.0-x32-SYS_getrandom.patch
			epatch "${FILESDIR}"/${PN}-52.1.0-musl-define-mmap.patch
			epatch "${FILESDIR}"/${PN}-52.1.0-x32-structs64-2.patch #test ##
		fi

		if use debug ; then
			#using use debug will run out of memory for ld
			#https://bugzilla.mozilla.org/show_bug.cgi?id=1094653
			append-ldflags -Wl,--reduce-memory-overheads
			append-ldflags -Wl,--no-keep-memory
		fi
	fi

	# Enable gnomebreakpad
	if use debug ; then
		sed -i -e "s:GNOME_DISABLE_CRASH_DIALOG=1:GNOME_DISABLE_CRASH_DIALOG=0:g" \
			"${S}"/build/unix/run-mozilla.sh || die "sed failed!"
	fi

	# Drop -Wl,--as-needed related manipulation for ia64 as it causes ld sefgaults, bug #582432
	if use ia64 ; then
		sed -i \
		-e '/^OS_LIBS += no_as_needed/d' \
		-e '/^OS_LIBS += as_needed/d' \
		"${S}"/widget/gtk/mozgtk/gtk2/moz.build \
		"${S}"/widget/gtk/mozgtk/gtk3/moz.build \
		|| die "sed failed to drop --as-needed for ia64"
	fi

	# Ensure that our plugins dir is enabled as default
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 64bit!"

	# Fix sandbox violations during make clean, bug 372817
	sed -e "s:\(/no-such-file\):${T}\1:g" \
		-i "${S}"/config/rules.mk \
		-i "${S}"/nsprpub/configure{.in,} \
		|| die

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}"/browser/installer/Makefile.in || die

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}"/toolkit/mozapps/installer/packager.mk || die

	# Keep codebase the same even if not using official branding
	sed '/^MOZ_DEV_EDITION=1/d' \
		-i "${S}"/browser/branding/aurora/configure.sh || die

	# Allow user to apply any additional patches without modifing ebuild
	eapply_user

	# Autotools configure is now called old-configure.in
	# This works because there is still a configure.in that happens to be for the
	# shell wrapper configure script
	eautoreconf old-configure.in

	# Must run autoconf in js/src
	cd "${S}"/js/src || die
	eautoconf old-configure.in

	# Need to update jemalloc's configure
	cd "${S}"/memory/jemalloc/src || die
	WANT_AUTOCONF= eautoconf
}

src_configure() {
	MEXTENSIONS="default"
	# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
	# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
	# get your own set of keys.
	_google_api_key=AIzaSyDEAOvatFo0eTgsV_ZlEzx0ObmepsMzfAc

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	mozconfig_init
	mozconfig_config

	# enable JACK, bug 600002
	mozconfig_use_enable jack

	# It doesn't compile on alpha without this LDFLAGS
	use alpha && append-ldflags "-Wl,--no-relax"

	# Add full relro support for hardened
	use hardened && append-ldflags "-Wl,-z,relro,-z,now"

	# Only available on mozilla-overlay for experimentation -- Removed in Gentoo repo per bug 571180
	#use egl && mozconfig_annotate 'Enable EGL as GL provider' --with-gl-provider=EGL

	# Setup api key for location services
	echo -n "${_google_api_key}" > "${S}"/google-api-key
	mozconfig_annotate '' --with-google-api-keyfile="${S}/google-api-key"

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"

	mozconfig_use_enable rust

	# Allow for a proper pgo build
	if use pgo; then
		echo "mk_add_options PROFILE_GEN_SCRIPT='EXTRA_TEST_ARGS=10 \$(MAKE) -C \$(MOZ_OBJDIR) pgo-profile-run'" >> "${S}"/.mozconfig
	fi

	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${S}"/.mozconfig
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${S}"/.mozconfig

	#this is here to allow firefox to install then later for the developer to run gdb debugger on firefox if startupcache generation fails
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		mozconfig_annotate '' --disable-startupcache
	fi

	# Finalize and report settings
	mozconfig_final

	if [[ $(gcc-major-version) -lt 4 ]]; then
		append-cxxflags -fno-stack-protector
	fi

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
	emake -f client.mk configure
}

src_compile() {
	if use pgo; then
		addpredict /root
		addpredict /etc/gconf
		# Reset and cleanup environment variables used by GNOME/XDG
		gnome2_environment_reset

		# Firefox tries to use dri stuff when it's run, see bug 380283
		shopt -s nullglob
		cards=$(echo -n /dev/dri/card* | sed 's/ /:/g')
		if test -z "${cards}"; then
			cards=$(echo -n /dev/ati/card* /dev/nvidiactl* | sed 's/ /:/g')
			if test -n "${cards}"; then
				# Binary drivers seem to cause access violations anyway, so
				# let's use indirect rendering so that the device files aren't
				# touched at all. See bug 394715.
				export LIBGL_ALWAYS_INDIRECT=1
			fi
		fi
		shopt -u nullglob
		[[ -n "${cards}" ]] && addpredict "${cards}"

		MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
		virtx emake -f client.mk profiledbuild || die "virtx emake failed"
	else
		MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
		emake -f client.mk realbuild
	fi

}

src_install() {
	cd "${BUILD_OBJ_DIR}" || die

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}"/dist/bin/xpcshell

	# Add our default prefs for firefox
	cp "${FILESDIR}"/gentoo-default-prefs.js-1 \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	mozconfig_install_prefs \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js"

	# Augment this with hwaccel prefs
	if use hwaccel ; then
		cat "${FILESDIR}"/gentoo-hwaccel-prefs.js-1 >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die
	fi

	echo "pref(\"extensions.autoDisableScopes\", 3);" >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	local plugin
	use gmp-autoupdate || for plugin in "${GMP_PLUGIN_LIST[@]}" ; do
		echo "pref(\"media.${plugin}.autoupdate\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	done

	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
	emake DESTDIR="${D}" install

	# Install language packs
	mozlinguas_src_install

	local size sizes icon_path icon name
	if use bindist; then
		sizes="16 32 48"
		icon_path="${S}/browser/branding/aurora"
		# Firefox's new rapid release cycle means no more codenames
		# Let's just stick with this one...
		icon="aurora"
		name="Aurora"

		# Override preferences to set the MOZ_DEV_EDITION defaults, since we
		# don't define MOZ_DEV_EDITION to avoid profile debaucles.
		# (source: browser/app/profile/firefox.js)
		cat >>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" <<PROFILE_EOF
pref("app.feedback.baseURL", "https://input.mozilla.org/%LOCALE%/feedback/firefoxdev/%VERSION%/");
sticky_pref("lightweightThemes.selectedThemeID", "firefox-devedition@mozilla.org");
sticky_pref("browser.devedition.theme.enabled", true);
sticky_pref("devtools.theme", "dark");
PROFILE_EOF

	else
		sizes="16 22 24 32 256"
		icon_path="${S}/browser/branding/official"
		icon="${PN}"
		name="Mozilla Firefox"
	fi

	# Install icons and .desktop for menu entry
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png"
	done
	# The 128x128 icon has a different name
	insinto "/usr/share/icons/hicolor/128x128/apps"
	newins "${icon_path}/mozicon128.png" "${icon}.png"
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}/content/icon48.png" "${icon}.png"
	newmenu "${FILESDIR}/icon/${PN}.desktop" "${PN}.desktop"
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}/usr/share/applications/${PN}.desktop" || die

	# Add StartupNotify=true bug 237317
	if use startup-notification ; then
		echo "StartupNotify=true"\
			 >> "${ED}/usr/share/applications/${PN}.desktop" \
			|| die
	fi

	# Required in order to use plugins and even run firefox on hardened.
	pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/{firefox,firefox-bin,plugin-container}
}

pkg_preinst() {
	gnome2_icon_savelist

	# if the apulse libs are available in MOZILLA_FIVE_HOME then apulse
	# doesn't need to be forced into the LD_LIBRARY_PATH
	if use pulseaudio && has_version ">=media-sound/apulse-0.1.9" ; then
		einfo "APULSE found - Generating library symlinks for sound support"
		local lib
		pushd "${ED}"${MOZILLA_FIVE_HOME} &>/dev/null || die
		for lib in ../apulse/libpulse{.so{,.0},-simple.so{,.0}} ; do
			# a quickpkg rolled by hand will grab symlinks as part of the package,
			# so we need to avoid creating them if they already exist.
			if ! [ -L ${lib##*/} ]; then
				ln -s "${lib}" ${lib##*/} || die
			fi
		done
		popd &>/dev/null || die
	fi
}

pkg_postinst() {
	# Update mimedb for the new .desktop file
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update

	if ! use gmp-autoupdate ; then
		elog "USE='-gmp-autoupdate' has disabled the following plugins from updating or"
		elog "installing into new profiles:"
		local plugin
		for plugin in "${GMP_PLUGIN_LIST[@]}"; do elog "\t ${plugin}" ; done
	fi

	if use pulseaudio && has_version ">=media-sound/apulse-0.1.9" ; then
		elog "Apulse was detected at merge time on this system and so it will always be"
		elog "used for sound.  If you wish to use pulseaudio instead please unmerge"
		elog "media-sound/apulse."
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
}
