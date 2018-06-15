# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
VIRTUALX_REQUIRED="pgo"
WANT_AUTOCONF="2.1"
MOZ_ESR=""

# This list can be updated with scripts/get_langs.sh from the mozilla overlay
# Excluding cak, dsb, ff, gn, lij as they arent on the gentoo list
MOZ_LANGS=( ach af an ar as ast az be bg bn-BD bn-IN br bs ca cs cy da de
el en en-GB en-US en-ZA eo es-AR es-CL es-ES es-MX et eu fa fi fr fy-NL
ga-IE gd gl gu-IN he hi-IN hr hsb hu hy-AM id is it ja kk km kn ko lt
lv mai mk ml mr ms nb-NO nl nn-NO or pa-IN pl pt-BR pt-PT rm ro ru si sk sl
son sq sr sv-SE ta te th tr uk uz vi xh zh-CN zh-TW )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_alpha/a}" # Handle alpha for SRC_URI
MOZ_PV="${MOZ_PV/_beta/b}" # Handle beta for SRC_URI
MOZ_PV="${MOZ_PV/_rc/rc}" # Handle rc for SRC_URI

if [[ ${MOZ_ESR} == 1 ]]; then
	# ESR releases have slightly different version numbers
	MOZ_PV="${MOZ_PV}esr"
fi

# Patch version
PATCH="${PN}-49.0-patches-02"
MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"

MOZCONFIG_OPTIONAL_GTK2ONLY=1
MOZCONFIG_OPTIONAL_WIFI=1
MOZCONFIG_OPTIONAL_JIT="enabled"

inherit check-reqs flag-o-matic toolchain-funcs eutils gnome2-utils mozconfig-v6.49 pax-utils fdo-mime autotools virtualx mozlinguas-v2

DESCRIPTION="Firefox Web Browser"
HOMEPAGE="http://www.mozilla.com/firefox"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist hardened +hwaccel pgo selinux +gmp-autoupdate test"
IUSE+=" experimental"
REQUIRED_USE="elibc_musl? ( abi_x86_x32? ( system-libvpx !jit )  ) !experimental" #fix experimental patches before removing
RESTRICT="!bindist? ( bindist )"

PATCH_URIS=( https://dev.gentoo.org/~{anarchy,axs,polynomial-c}/mozilla/patchsets/${PATCH}.tar.xz )
SRC_URI="${SRC_URI}
	${MOZ_HTTP_URI}/${MOZ_PV}/source/firefox-${MOZ_PV}.source.tar.xz
	${PATCH_URIS[@]}"

ASM_DEPEND=">=dev-lang/yasm-1.1"

RDEPEND="
	>=dev-libs/nss-3.25
	>=dev-libs/nspr-4.12
	selinux? ( sec-policy/selinux-mozilla )"

DEPEND="${RDEPEND}
	pgo? ( >=sys-devel/gcc-4.5 )
	amd64? ( ${ASM_DEPEND} virtual/opengl )
	x86? ( ${ASM_DEPEND} virtual/opengl )"

S="${WORKDIR}/firefox-${MOZ_PV}"

QA_PRESTRIPPED="usr/lib*/${PN}/firefox"

BUILD_OBJ_DIR="${S}/ff"

pkg_setup() {
        if [[ "${CHOST}" =~ "muslx32" ]] ; then
                ewarn "this ebuild doesn't work for muslx32.  it is left for ebuild developers to work on it."
		ewarn "reason: segfaults.  fix x32 javascript support."
		if [[ "${MUSLX32_OVERLAY_DEVELOPER}" != "1" ]] ; then
			eerror "add MUSLX32_OVERLAY_DEVELOPER=1 to /etc/portage/make.conf to continue emerging broken package."
			die
		fi
#it could be related to https://bugzilla.mozilla.org/show_bug.cgi?id=1325495

#make -j1 DESTDIR=/var/tmp/portage/www-client/firefox-49.0/image/ install 
#make[1]: Entering directory '/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/ff/browser/installer'
#OMNIJAR_NAME=omni.ja \
#NO_PKG_FILES="core bsdecho js js-config jscpucfg nsinstall viewer TestGtkEmbed elf-dynstr-gc mangle* maptsv* mfc* msdump* msmap* nm2tsv* nsinstall* res/samples res/throbber shlibsign* certutil* pk12util* BadCertServer* OCSPStaplingServer* GenerateOCSPResponse* chrome/chrome.rdf chrome/app-chrome.manifest chrome/overlayinfo components/compreg.dat components/xpti.dat content_unit_tests necko_unit_tests *.dSYM " \
#/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/ff/_virtualenv/bin/python /var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/toolkit/mozapps/installer/packager.py -DMOZ_APP_NAME=firefox -DPREF_DIR=defaults/preferences -DMOZ_GTK=1 -DMOZ_GTK3=1 -DMOZ_SYSTEM_NSPR=1 -DMOZ_SYSTEM_NSS=1 -DJAREXT= -DMOZ_CHILD_PROCESS_NAME=plugin-container -DDLL_PREFIX=lib -DDLL_SUFFIX=.so -DBIN_SUFFIX= -DDIR_MACOS= -DDIR_RESOURCES= -DBINPATH=bin -DRESPATH=bin -DLPROJ_ROOT=en -DMOZ_ICU_VERSION=56 -DMOZ_ICU_DATA_ARCHIVE -DMOZ_ICU_DBG_SUFFIX= -DICU_DATA_FILE=icudt56l.dat -DA11Y_LOG=1 -DACCESSIBILITY=1 -DATK_MAJOR_VERSION=2 -DATK_MINOR_VERSION=22 -DATK_REV_VERSION=0 -DATTRIBUTE_ALIGNED_MAX=64 -DBUILD_CTYPES=1 -DCROSS_COMPILE='' -DD_INO=d_ino -DENABLE_INTL_API=1 -DENABLE_MARIONETTE=1 -DENABLE_SYSTEM_EXTENSION_DIRS=1 -DEXPOSE_INTL_API=1 -DFIREFOX_VERSION=49.0 -DFORCE_PR_LOG=1 -DFUNCPROTO=15 -DGDK_VERSION_MAX_ALLOWED=GDK_VERSION_3_4 -DGDK_VERSION_MIN_REQUIRED=GDK_VERSION_3_4 -DGLIB_VERSION_MAX_ALLOWED=GLIB_VERSION_2_32 -DGLIB_VERSION_MIN_REQUIRED=GLIB_VERSION_2_26 -DGL_PROVIDER_GLX=1 -DHAVE_ALLOCA_H=1 -DHAVE_BYTESWAP_H=1 -DHAVE_CLOCK_MONOTONIC=1 -DHAVE_CPUID_H=1 -DHAVE_DIRENT_H=1 -DHAVE_DLADDR=1 -DHAVE_DLOPEN=1 -DHAVE_FONTCONFIG_FCFREETYPE_H=1 -DHAVE_FT_BITMAP_SIZE_Y_PPEM=1 -DHAVE_FT_GLYPHSLOT_EMBOLDEN=1 -DHAVE_FT_LOAD_SFNT_TABLE=1 -DHAVE_GETOPT_H=1 -DHAVE_GMTIME_R=1 -DHAVE_I18N_LC_MESSAGES=1 -DHAVE_INTTYPES_H=1 -DHAVE_LANGINFO_CODESET=1 -DHAVE_LCHOWN=1 -DHAVE_LIBPNG=1 -DHAVE_LIBVPX=1 -DHAVE_LIBXSS=1 -DHAVE_LINUX_IF_ADDR_H=1 -DHAVE_LINUX_QUOTA_H=1 -DHAVE_LINUX_RTNETLINK_H=1 -DHAVE_LOCALECONV=1 -DHAVE_LOCALTIME_R=1 -DHAVE_LSTAT64=1 -DHAVE_MALLOC_H=1 -DHAVE_MALLOC_USABLE_SIZE=1 -DHAVE_MEMALIGN=1 -DHAVE_MEMMEM=1 -DHAVE_MEMORY_H=1 -DHAVE_NETINET_IN_H=1 -DHAVE_NL_TYPES_H=1 -DHAVE_POSIX_FADVISE=1 -DHAVE_POSIX_FALLOCATE=1 -DHAVE_POSIX_MEMALIGN=1 -DHAVE_PTHREAD_H=1 -DHAVE_SETPRIORITY=1 -DHAVE_STAT64=1 -DHAVE_STDINT_H=1 -DHAVE_STRERROR=1 -DHAVE_STRNDUP=1 -DHAVE_SYSCALL=1 -DHAVE_SYS_QUEUE_H=1 -DHAVE_SYS_QUOTA_H=1 -DHAVE_SYS_SYSMACROS_H=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_THREAD_TLS_KEYWORD=1 -DHAVE_TRUNCATE64=1 -DHAVE_UNISTD_H=1 -DHAVE_VALLOC=1 -DHAVE_VA_COPY=1 -DHAVE_VA_LIST_AS_ARRAY=1 -DHAVE_VISIBILITY_ATTRIBUTE=1 -DHAVE_VISIBILITY_HIDDEN_ATTRIBUTE=1 -DHAVE_X11_XKBLIB_H=1 -DHAVE__UNWIND_BACKTRACE=1 -DHAVE___CXA_DEMANGLE=1 -DJS_DEFAULT_JITREPORT_GRANULARITY=3 -DMALLOC_H='<malloc.h>' -DMALLOC_USABLE_SIZE_CONST_PTR='' -DMOZILLA_UAVERSION='"49.0"' -DMOZILLA_VERSION='"49.0"' -DMOZILLA_VERSION_U=49.0 -DMOZ_ACCESSIBILITY_ATK=1 -DMOZ_ACTIVITIES=1 -DMOZ_APP_UA_NAME='""' -DMOZ_APP_UA_VERSION='"49.0"' -DMOZ_B2G_OS_NAME='""' -DMOZ_B2G_VERSION='"1.0.0"' -DMOZ_BUILD_APP=browser -DMOZ_CRASHREPORTER_ENABLE_PERCENT=100 -DMOZ_DATA_REPORTING=1 -DMOZ_DEFAULT_MOZILLA_FIVE_HOME='"/usr/lib/firefox"' -DMOZ_DISTRIBUTION_ID='"org.mozilla"' -DMOZ_DLL_SUFFIX='".so"' -DMOZ_EME=1 -DMOZ_ENABLE_GIO=1 -DMOZ_ENABLE_SIGNMAR=1 -DMOZ_ENABLE_SKIA=1 -DMOZ_ENABLE_XREMOTE=1 -DMOZ_FEEDS=1 -DMOZ_FFMPEG=1 -DMOZ_FFVPX=1 -DMOZ_FMP4=1 -DMOZ_GAMEPAD=1 -DMOZ_GLUE_IN_PROGRAM=1 -DMOZ_GMP_SANDBOX=1 -DMOZ_INSTRUMENT_EVENT_LOOP=1 -DMOZ_JSDOWNLOADS=1 -DMOZ_LIBAV_FFT=1 -DMOZ_LOGGING=1 -DMOZ_MACBUNDLE_ID=org.mozilla.firefoxdeveloperedition -DMOZ_PAY=1 -DMOZ_PEERCONNECTION=1 -DMOZ_PERMISSIONS=1 -DMOZ_PHOENIX=1 -DMOZ_PLACES=1 -DMOZ_RAW=1 -DMOZ_SAFE_BROWSING=1 -DMOZ_SAMPLE_TYPE_FLOAT32=1 -DMOZ_SANDBOX=1 -DMOZ_SCTP=1 -DMOZ_SECUREELEMENT=1 -DMOZ_SERVICES_HEALTHREPORT=1 -DMOZ_SRTP=1 -DMOZ_STACKWALKING=1 -DMOZ_STATIC_JS=1 -DMOZ_TREE_CAIRO=1 -DMOZ_TREE_PIXMAN=1 -DMOZ_UPDATE_CHANNEL=default -DMOZ_URL_CLASSIFIER=1 -DMOZ_USER_DIR='".mozilla"' -DMOZ_VORBIS=1 -DMOZ_VPX_ERROR_CONCEALMENT=1 -DMOZ_VPX_NO_MEM_REPORTING=1 -DMOZ_WEBGL_CONFORMANT=1 -DMOZ_WEBM_ENCODER=1 -DMOZ_WEBRTC=1 -DMOZ_WEBRTC_ASSERT_ALWAYS=1 -DMOZ_WEBRTC_SIGNALING=1 -DMOZ_WEBSPEECH=1 -DMOZ_WEBSPEECH_TEST_BACKEND=1 -DMOZ_WIDGET_GTK=3 -DMOZ_X11=1 -DMOZ_XUL=1 -DNO_NSPR_10_SUPPORT=1 -DNS_PRINTING=1 -DNS_PRINT_PREVIEW=1 -DRELEASE_BUILD=1 -DSTATIC_JS_API=1 -DSTDC_HEADERS=1 -DTARGET_XPCOM_ABI='"x86_64-gcc3"' -DUSE_SKIA=1 -DUSE_SKIA_GPU=1 -DU_STATIC_IMPLEMENTATION=1 -DU_USING_ICU_NAMESPACE=0 -DVA_COPY=va_copy -DXP_LINUX=1 -DXP_UNIX=1 -D_REENTRANT=1 -DAB_CD=en-US \
#	--format omni \
#	--removals /var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/browser/installer/removed-files.in \
#	--ignore-errors \
#	 \
#	 \
#	 \
#	--optimizejars \
#	 \
#	 \
#	/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/browser/installer/package-manifest.in ../../dist ../../dist/firefox \
#	
#Executing /var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/ff/dist/bin/xpcshell -g /var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/ff/dist/bin/ -a /var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/ff/dist/bin/ -f /var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/toolkit/mozapps/installer/precompile_cache.js -e precompile_startupcache("resource://gre/");
#Traceback (most recent call last):
#  File "/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/toolkit/mozapps/installer/packager.py", line 415, in <module>
#    main()
#  File "/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/toolkit/mozapps/installer/packager.py", line 409, in main
#    args.source, gre_path, base)
#  File "/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/toolkit/mozapps/installer/packager.py", line 166, in precompile_cache
#    errors.fatal('Error while running startup cache precompilation')
#  File "/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/python/mozbuild/mozpack/errors.py", line 103, in fatal
#    self._handle(self.FATAL, msg)
#  File "/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/python/mozbuild/mozpack/errors.py", line 98, in _handle
#    raise ErrorMessage(msg)
#mozpack.errors.ErrorMessage: Error: Error while running startup cache precompilation
#make[1]: *** [/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/toolkit/mozapps/installer/packager.mk:41: stage-package] Error 1
#make[1]: Leaving directory '/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/ff/browser/installer'
#make: *** [/var/tmp/portage/www-client/firefox-49.0/work/firefox-49.0/browser/build.mk:21: install] Error 2
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
#		"${FILESDIR}"/${PN}-48.0-pgo.patch

	#fix http2/http1 bug
	epatch "${FILESDIR}"/curve-ff.patch

	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		if [[ "${CHOST}" =~ "musl" ]]; then
			sed -i "s|#include <sys/cdefs.h>|#include <sys/types.h>|g" ./security/sandbox/chromium/sandbox/linux/seccomp-bpf/linux_seccomp.h || die "musl patch failed"
			cp "${FILESDIR}"/stab.h "${S}"/toolkit/crashreporter/google-breakpad/src/ || die "failed to copy stab.h"
			epatch "${FILESDIR}"/${PN}-38.8.0-blocksize-musl.patch
			epatch "${FILESDIR}"/${PN}-38.8.0-updater.patch
		fi
		if use abi_x86_x32; then
			append-cppflags -DOS_LINUX=1 #1
			epatch "${FILESDIR}"/${PN}-38.8.0-dont-use-amd64-ycbcr-on-x32.patch #2
			epatch "${FILESDIR}"/${PN}-38.8.0-fix-non-__lp64__-for-x32.patch
			epatch "${FILESDIR}"/${PN}-49.0-disable-breakpad-on-x32.patch ##
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
			epatch "${FILESDIR}"/${PN}-49.0-x32-structs64.patch #test ##
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

				epatch "${FILESDIR}"/${PN}-47.0.1-ffvpx-moz_build.patch #disables simd for ffvpx
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
			epatch "${FILESDIR}"/${PN}-47.0.1-disable-hw-intel-aes.patch
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

	#might want to enable this to install it then debug... if left commented, it will crash when generating startup cache.
	#if [[ "${CHOST}" =~ "musl" ]]; then
        #    mozconfig_annotate '' --disable-startupcache
        #fi

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
		addpredict "${cards}"

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
	use gmp-autoupdate || for plugin in \
	gmp-gmpopenh264 ; do
		echo "pref(\"media.${plugin}.autoupdate\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	done

	MOZ_MAKE_FLAGS="${MAKEOPTS}" \
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

	# Required in order to use plugins and even run firefox on hardened, with jit useflag.
	if use jit; then
		pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/{firefox,firefox-bin,plugin-container}
	else
		pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/plugin-container
	fi

	# very ugly hack to make firefox not sigbus on sparc
	# FIXME: is this still needed??
	use sparc && { sed -e 's/Firefox/FirefoxGentoo/g' \
					 -i "${ED}/${MOZILLA_FIVE_HOME}/application.ini" \
					|| die "sparc sed failed"; }
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	# Update mimedb for the new .desktop file
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
