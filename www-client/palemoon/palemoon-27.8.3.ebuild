EAPI=6

REQUIRED_BUILDSPACE='7G'
GCC_SUPPORTED_VERSIONS="4.7 4.9"

inherit palemoon-4 git-r3 eutils flag-o-matic pax-utils \
	multilib multilib-minimal

KEYWORDS="~x86 ~amd64"
DESCRIPTION="Pale Moon Web Browser"
HOMEPAGE="https://www.palemoon.org/"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="+official-branding
	+optimize cpu_flags_x86_sse cpu_flags_x86_sse2 threads debug
	-system-libevent -system-zlib -system-bzip2 -system-libwebp -system-libvpx
	-system-sqlite
	shared-js jemalloc -valgrind dbus -necko-wifi +gtk2 -gtk3
	alsa pulseaudio +devtools"

EGIT_REPO_URI="https://github.com/MoonchildProductions/Pale-Moon.git"
GIT_TAG="${PV}_Release"

RESTRICT="mirror"

DEPEND="
	>=sys-devel/autoconf-2.13:2.1
	dev-lang/python:2.7
	>=dev-lang/perl-5.6
	dev-lang/yasm"

RDEPEND="
	x11-libs/libXt[${MULTILIB_USEDEP}]
	app-arch/zip
	media-libs/freetype[${MULTILIB_USEDEP}]
	media-libs/fontconfig[${MULTILIB_USEDEP}]

	system-libevent? ( dev-libs/libevent[${MULTILIB_USEDEP}] )
	system-zlib?     ( sys-libs/zlib[${MULTILIB_USEDEP}] )
	system-bzip2?    ( app-arch/bzip2[${MULTILIB_USEDEP}] )
	system-libwebp?  ( media-libs/libwebp[${MULTILIB_USEDEP}] )
	system-libvpx?   ( >=media-libs/libvpx-1.4.0[${MULTILIB_USEDEP}] )
	system-sqlite?   ( >=dev-db/sqlite-3.21.0[secure-delete,${MULTILIB_USEDEP}] )

	optimize? ( sys-libs/glibc[${MULTILIB_USEDEP}] )

	valgrind? ( dev-util/valgrind )

	shared-js? ( virtual/libffi[${MULTILIB_USEDEP}] )

	dbus? (
		>=sys-apps/dbus-0.60[${MULTILIB_USEDEP}]
		>=dev-libs/dbus-glib-0.60[${MULTILIB_USEDEP}]
	)

	gtk2? ( >=x11-libs/gtk+-2.18.0:2[${MULTILIB_USEDEP}]
		x11-libs/libXrender[${MULTILIB_USEDEP}]
		dev-libs/glib:2[${MULTILIB_USEDEP}]
		x11-libs/libXau[${MULTILIB_USEDEP}]
		x11-proto/renderproto[${MULTILIB_USEDEP}]
		x11-proto/xproto[${MULTILIB_USEDEP}]
		x11-libs/libXfixes[${MULTILIB_USEDEP}]
		x11-proto/xextproto[${MULTILIB_USEDEP}]
              )
	gtk3? ( >=x11-libs/gtk+-3.4.0:3[${MULTILIB_USEDEP}] )

	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )

	virtual/ffmpeg[x264,${MULTILIB_USEDEP}]

	necko-wifi? ( net-wireless/wireless-tools )"

REQUIRED_USE="
	optimize? ( !debug )
	jemalloc? ( !valgrind )
	^^ ( gtk2 gtk3 )
	alsa? ( !pulseaudio )
	pulseaudio? ( !alsa )
	necko-wifi? ( dbus )"

src_unpack() {
	git-r3_fetch ${EGIT_REPO_URI} refs/tags/${GIT_TAG}
	git-r3_checkout
}

src_prepare() {
	# Ensure that our plugins dir is enabled by default:
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}/xpcom/io/nsAppFileLocationProvider.cpp" \
		|| die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}/xpcom/io/nsAppFileLocationProvider.cpp" \
		|| die "sed failed to replace plugin path for 64bit!"

if false ; then
	if [[ "${CHOST}" =~ "muslx32" ]] ; then
		if [[ "${CHOST}" =~ "musl" ]]; then
			sed -i "s|#include <sys/cdefs.h>|#include <sys/types.h>|g" ./security/sandbox/chromium/sandbox/linux/seccomp-bpf/linux_seccomp.h || die "musl patch failed"
			# cp "${FILESDIR}"/stab.h "${S}"/toolkit/crashreporter/google-breakpad/src/ || die "failed to copy stab.h"
			epatch "${FILESDIR}"/firefox-38.8.0-blocksize-musl.patch
			epatch "${FILESDIR}"/firefox-38.8.0-updater.patch
		fi
		if use abi_x86_x32; then
			append-cppflags -DOS_LINUX=1 #1
			epatch "${FILESDIR}"/firefox-38.8.0-dont-use-amd64-ycbcr-on-x32.patch #2
			epatch "${FILESDIR}"/firefox-38.8.0-fix-non-__lp64__-for-x32.patch
			#epatch "${FILESDIR}"/firefox-34.0-disable-breakpad-on-x32.patch
				#this indented line below is mutually exclusive to jit set
				epatch "${FILESDIR}"/firefox-34.0-no-jit-on-x32.patch #renable
			#if use system-jpeg ; then
			#	epatch "${FILESDIR}"/firefox-45.2.0-enable-jpegturbo-optimizations-on-x32.patch #doesn't work if system-jpeg is disabled
			#else
				epatch "${FILESDIR}"/palemoon-27.8.3-disable-jpegturbo-x32-asm.patch #testing
			#fi
			#epatch "${FILESDIR}"/firefox-45.2-memory_mapped_file.patch
			#epatch "${FILESDIR}"/firefox-45.2.0-linux_syscall_support_h.patch
			#epatch "${FILESDIR}"/firefox-45.2.0-elf_core_dump_h.patch
			#epatch "${FILESDIR}"/firefox-45.2.0-sysdef.patch #part of cashreporter
			#epatch "${FILESDIR}"/firefox-45.2.0-linux_syscall_support_h-x32.patch # part of crashreporter
			#epatch "${FILESDIR}"/firefox-45.2.0-stat-x32.patch # part of crashreporter
			#epatch "${FILESDIR}"/firefox-45.2.0-libav-asflags.patch
			sed -i 's|-f elf64|-f elfx32|' ./configure.in || die "sed failed for elfx32 (1)"
			#sed -i 's|-f elf64|-f elfx32|' ./configure || die "sed failed for elfx32 (2)"
			#epatch "${FILESDIR}"/firefox-45.2.0-x32-structs64.patch # part of crashreporter
			epatch "${FILESDIR}"/firefox-47.0.1-xpcom-x32.patch
			#epatch "${FILESDIR}"/firefox-47.0.1-disable-hw-intel-aes.patch #fixme
				#the indented set is trying to fix jit... still broken
				#epatch "${FILESDIR}"/firefox-45.2.0-jit-x32-1.patch #enable for punbox64 have punbox64
				#epatch "${FILESDIR}"/firefox-45.2.0-jit-x32-2.patch #asmjs padding #required for jit

				#epatch "${FILESDIR}"/firefox-45.2.0-jit-x32-punbox64-1.patch

				#epatch "${FILESDIR}"/firefox-45.2.0-jit-x32-nunbox32-1.patch
				#epatch "${FILESDIR}"/firefox-45.2.0-jit-x32-nunbox32-2.patch
			#epatch "${FILESDIR}"/firefox-45.4.0-event-size-symbol-rename.patch #for >=libevent-2.1.8 # code doesn't exist
			epatch "${FILESDIR}"/palemoon-27.8.3-virtualenv-multilib.patch
		fi

		if use debug ; then
			#using use debug will run out of memory for ld
			#https://bugzilla.mozilla.org/show_bug.cgi?id=1094653
			append-ldflags -Wl,--reduce-memory-overheads
			append-ldflags -Wl,--no-keep-memory
		fi
	fi
else
	epatch "${FILESDIR}"/palemoon-27.8.3-virtualenv-multilib.patch
fi

	default
	multilib_copy_sources
}

multilib_src_configure() {
	einfo "CFLAGS_x32=${CFLAGS_x32}"
	#export CC="${CC} -mx32 -B/usr/x86_64-pc-linux-muslx32/usr/bin -B/usr/x86_64-pc-linux-muslx32/usr/lib -I/usr/x86_64-pc-linux-muslx32/usr/include -B/usr/lib/gcc/x86_64-pc-linux-muslx32/7.3.0"
	#export CXX="${CXX} -mx32 -B/usr/x86_64-pc-linux-muslx32/usr/bin -B/usr/x86_64-pc-linux-muslx32/usr/lib -I/usr/x86_64-pc-linux-muslx32/usr/include -B/usr/lib/gcc/x86_64-pc-linux-muslx32/7.3.0"
	#append-cflags ${CFLAGS_x32}
	#append-cxxflags ${CFLAGS_x32}
	# Basic configuration:
	mozconfig_init

	mozconfig_disable installer updater install-strip

	if use official-branding; then
		official-branding_warning
		mozconfig_enable official-branding
	fi

	if use system-libevent; then mozconfig_with system-libevent; fi
	if use system-zlib;     then mozconfig_with system-zlib; fi
	if use system-bzip2;    then mozconfig_with system-bz2; fi
	if use system-libwebp;  then mozconfig_with system-webp; fi
	if use system-libvpx;   then mozconfig_with system-libvpx; fi
	if use system-sqlite;   then mozconfig_enable system-sqlite; fi

	if use optimize; then
		O='-O2'
		if use cpu_flags_x86_sse && use cpu_flags_x86_sse2; then
			O="${O} -msse2 -mfpmath=sse"
		fi
		mozconfig_enable "optimize=\"${O}\""
		filter-flags '-O*' '-msse2' '-mfpmath=sse'
	else
		mozconfig_disable optimize
	fi

	if use threads; then
		mozconfig_with pthreads
	fi

	if use debug; then
		mozconfig_var MOZ_DEBUG_SYMBOLS 1
		mozconfig_enable "debug-symbols=\"-gdwarf-2\""
	fi

	if use shared-js; then
		mozconfig_enable shared-js
	fi

	if use jemalloc; then
		mozconfig_enable jemalloc jemalloc-lib
	fi

	if use valgrind; then
		mozconfig_enable valgrind
	fi

	if ! use dbus; then
		mozconfig_disable dbus
	fi

	if use gtk2; then
		mozconfig_enable default-toolkit=\"cairo-gtk2\"
	fi

	if use gtk3; then
		mozconfig_enable default-toolkit=\"cairo-gtk3\"
	fi

	if ! use necko-wifi; then
		mozconfig_disable necko-wifi
	fi

	if   use alsa; then
		mozconfig_enable alsa
	fi

	if ! use pulseaudio; then
		mozconfig_disable pulseaudio
	fi

	if use devtools; then
		mozconfig_enable devtools
	fi

	# Mainly to prevent system's NSS/NSPR from taking precedence over
	# the built-in ones:
	append-ldflags -Wl,-rpath="$EPREFIX/usr/$(get_libdir)/palemoon"

	export MOZBUILD_STATE_PATH="${WORKDIR}/mach_state"
	mozconfig_var PYTHON $(which python2)
	mozconfig_var AUTOCONF $(which autoconf-2.13)
	mozconfig_var MOZ_MAKE_FLAGS "\"${MAKEOPTS}\""

	# Shorten obj dir to limit some errors linked to the path size hitting
	# a kernel limit (127 chars):
	mozconfig_var MOZ_OBJDIR "@TOPSRCDIR@/o"

	# Disable mach notifications, which also cause sandbox access violations:
	export MOZ_NOSPAM=1
}

multilib_src_compile() {
	python2 mach build || die
}

multilib_src_install() {
	# obj_dir changes depending on arch, compiler, etc:
	local obj_dir="$(echo */config.log)"
	obj_dir="${obj_dir%/*}"

	# Disable MPROTECT for startup cache creation:
	pax-mark m "${obj_dir}"/dist/bin/xpcshell

	# Set the backspace behaviour to be consistent with the other platforms:
	set_pref "browser.backspace_action" 0

	# Gotta create the package, unpack it and manually install the files
	# from there not to miss anything (e.g. the statusbar extension):
	einfo "Creating the package..."
	python2 mach package || die
	local extracted_dir="${T}/package"
	mkdir -p "${extracted_dir}"
	cd "${extracted_dir}"
	einfo "Extracting the package..."
	tar xjpf "${S}/${obj_dir}/dist/${P}.linux-${CTARGET_default%%-*}.tar.bz2"
	einfo "Installing the package..."
	local dest_libdir="/usr/$(get_libdir)"
	mkdir -p "${D}/${dest_libdir}"
	cp -rL "${PN}" "${D}/${dest_libdir}"
	dosym "${dest_libdir}/${PN}/${PN}" "/usr/bin/${PN}"
	einfo "Done installing the package."

	# Until JIT-less builds are supported,
	# also disable MPROTECT on the main executable:
	pax-mark m "${D}/${dest_libdir}/${PN}/"{palemoon,palemoon-bin,plugin-container}

	# Install icons and .desktop for menu entry:
	install_branding_files
}
