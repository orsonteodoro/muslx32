# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

#
# don't monkey with this ebuild unless contacting portage devs.
# period.
#

inherit eutils flag-o-matic toolchain-funcs multilib unpacker multiprocessing pax-utils

DESCRIPTION="sandbox'd LD_PRELOAD hack"
HOMEPAGE="https://www.gentoo.org/proj/en/portage/sandbox/"
SRC_URI="mirror://gentoo/${P}.tar.xz
	https://dev.gentoo.org/~vapier/dist/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="multilib"

DEPEND="app-arch/xz-utils
	>=app-misc/pax-utils-0.1.19" #265376
RDEPEND=""

EMULTILIB_PKG="true"
has sandbox_death_notice ${EBUILD_DEATH_HOOKS} || EBUILD_DEATH_HOOKS="${EBUILD_DEATH_HOOKS} sandbox_death_notice"

sandbox_death_notice() {
	ewarn "If configure failed with a 'cannot run C compiled programs' error, try this:"
	ewarn "FEATURES=-sandbox emerge sandbox"
}

sb_get_install_abis() { use multilib && get_install_abis || echo ${ABI:-default} ; }

sb_foreach_abi() {
	local OABI=${ABI}
	for ABI in $(sb_get_install_abis) ; do
		cd "${WORKDIR}/build-${ABI}"
		einfo "Running $1 for ABI=${ABI}..."
		"$@"
	done
	ABI=${OABI}
}

src_unpack() {
	unpacker
	cd "${S}"
	epatch "${FILESDIR}"/${P}-memory-corruption.patch #568714
	epatch "${FILESDIR}"/${P}-disable-same.patch
	epatch "${FILESDIR}"/${PN}-2.6-musl.patch
	epatch "${FILESDIR}"/${P}-fix-visibility-musl.patch
	epatch_user

	einfo "Applying automake musl patch"
        for file in $(grep -l -r -e "\$(am__cd) \$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target" "${WORKDIR}"); do
		einfo "Editing $file"
		sed -i 's|(\$(am__cd) \$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target) |$(am__cd) $(CURDIR)/$$subdir \&\& $(MAKE) $(AM_MAKEFLAGS) $$local_target |g' "$file"
        done

        for file in $(grep -l -r -e "\$(am__cd) \$(srcdir)/\$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target" "${WORKDIR}"); do
		einfo "Editing $file"
		sed -i 's|\$(am__cd) \$(srcdir)/\$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target |$(am__cd) $(CURDIR)/$$subdir \&\& $(MAKE) $(AM_MAKEFLAGS) $$local_target |g' "$file"
        done
	for file in $(find "${WORKDIR}" -name "Makefile.in"); do
		einfo "Editing $file"
	        sed -i 's|install\: install-recursive\n|install\: install-recursive install-am\n|g' "$file"
	       #sed -i -e ':a' -e 'N' -e '$!ba' -e 's|install\: install-recursive\n|install\: install-recursive install-am\n|g' "$file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|all: all-recursive\n|all: all-recursive all-am\n|g' "$file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|install: install-recursive\n|install: install-recursive install-am\n|g' "$file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|install: \$(BUILT_SOURCES)\n|install: $(BUILT_SOURCES) install-am\n|g' "$file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|all: \$(BUILT_SOURCES) config.h\n|all: $(BUILT_SOURCES) config.h all-am\n|g' "$file"
	done
	einfo "Applying libtool musl patch"
        for file in $(grep -l -r -e "\$\$files" "${WORKDIR}"); do
		einfo "Editing $file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|for p in \$\$list\; do \\\n\t  if test -f "\$\$p"\; then d=\; else d="\$(srcdir)\/"\; fi\; \\\n\t  echo "\$$d\$\$p"\; \\|for p in $$list; do \\\n\t  if [[ -f "$(CURDIR)/$$p" ]]; then \\\n\t    d="$(CURDIR)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$(srcdir)/$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$p"; \\\n\t  fi; \\|g' "$file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|if test -f \$\$p\; then d=\; else d="\$(srcdir)\/"\; fi\; \\\n\t  echo "\$\$d\$\$p"\; echo "\$\$\p"\; \\|if [[ -f "$(CURDIR)/$$p" ]]; then \\\n\t    d="$(CURDIR)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$(srcdir)/$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$$p" ]]; then \\\n\t    echo "$$p"; \\\n\t  fi; \\|g' "$file"
		#test this
		#sed -i -e ':a' -e 'N' -e '$!ba' -e 's|if test -f \$\$p\; then d=\; else d="\$(srcdir)\/"\; fi\; \\\n\t  echo "\$\$d\$\$p"\; echo "\$\$\p"\; \\|if [[ -f "$(CURDIR)"/$$p ]]; then \\\n\t    d="$(CURDIR)/"; \\\n\t    echo "$$d$$p"\; \\\t  elif [[ -f "$(srcdir)/$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$d$$p"\; \\\t  elif [[ -f "$$p" ]]; then \\\n\t    echo "$$p"\; \\\n\t  fi; \\|g' "$file"
		#original
		#sed -i -e ':a' -e 'N' -e '$!ba' -e 's|if test -f \$\$p\; then d=\; else d="\$(srcdir)\/"\; fi\; \\\n\t  echo "\$\$d\$\$p"\; echo "\$\$\p"\; \\|if [[ -f "$(CURDIR)"/$$p ]]; then \\\n\t    d="$(CURDIR)/"; \\\n\t    echo "$$d$$p"\; echo "$$p"\; \\\n\t  elif [[ -f "$(srcdir)/$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$d$$p"\; echo "$$p"\; \\\n\t  elif [[ -f "$$p" ]]; then \\\n\t    echo "$$p"\; echo "$$p"\; \\\n\t  fi; \\|g' "$file"
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|echo " \$(\([-_a-zA-Z0-9]*\)) \$\$files \x27\$(DESTDIR)\$(\([-_a-zA-Z0-9]*\))\x27"\; \\\n\t  \$([-_a-zA-Z0-9]*) \$\$files "\$(DESTDIR)\$([-_a-zA-Z0-9]*)" \|\| exit \$\$?\; \\|if \[\[ -d "$$files" \|\| -z "$$files" \]\]\; then \\\n\t    continue; \\\n\t  fi; \\\n\t  echo " $(\1) $$files \x27$(DESTDIR)$(\2)\x27"; \\\n\t  $(\1) $$files "$(DESTDIR)$(\2)" \|\| exit $$?; \\|g' "$file"	
		sed -i -e ':a' -e 'N' -e '$!ba' -e 's|test -z "\$\$files" \|\| { echo " \$(\([-_a-zA-Z0-9]*\)) \$(srcdir)\/\$\$files \x27\$(DESTDIR)\$(\([-_a-zA-Z0-9]*\))\x27"\; \\\n\t  \$([-_a-zA-Z0-9]*) \$(srcdir)\/\$\$files "\$(DESTDIR)\$([-_a-zA-Z0-9]*)" \|\| exit \$\$?\; }\; \\|if \[\[ -d "$$files" \|\| -z "$$files" \]\]\; then \\\n\t    continue; \\\n\t  fi; \\\n\t  echo " $(\1) $$files \x27$(DESTDIR)$(\2)\x27"; \\\n\t  $(\1) $$files "$(DESTDIR)$(\2)" \|\| exit $$?; \\|g' "$file"	
                sed -i -e ':a' -e 'N' -e '$!ba' -e 's|test -z "\$\$files" \|\| { \\\n\t    echo " \$(\([-_a-zA-Z0-9]*\)) \$\$files \x27\$(DESTDIR)\$(\([-_a-zA-Z0-9]*\))\x27"\; \\\n\t    \$([-_a-zA-Z0-9]*) \$\$files "\$(DESTDIR)\$([-_a-zA-Z0-9]*)" \|\| exit \$\$?\; }\; \\|if \[\[ -d "$$files" \|\| -z "$$files" \]\]\; then \\\n\t    continue; \\\n\t  fi; \\\n\t  echo " $(\1) $$files \x27$(DESTDIR)$(\2)\x27"; \\\n\t  $(\1) $$files "$(DESTDIR)$(\2)" \|\| exit $$?; \\|g' "$file"
	done
	epatch "${FILESDIR}"/${PN}-2.10-musl.patch
}

sb_configure() {
	mkdir "${WORKDIR}/build-${ABI}"
	cd "${WORKDIR}/build-${ABI}"

	use multilib && multilib_toolchain_setup ${ABI}

	local myconf=()
	host-is-pax && myconf+=( --disable-pch ) #301299 #425524 #572092

	einfo "Configuring sandbox for ABI=${ABI}..."
	ECONF_SOURCE="${S}" \
	econf ${myconf} || die
}

sb_compile() {
	emake || die
}

src_compile() {
	filter-lfs-flags #90228

	# Run configures in parallel!
	multijob_init
	local OABI=${ABI}
	for ABI in $(sb_get_install_abis) ; do
		multijob_child_init sb_configure
	done
	ABI=${OABI}
	multijob_finish

	sb_foreach_abi sb_compile
}

sb_test() {
	emake check TESTSUITEFLAGS="--jobs=$(makeopts_jobs)" || die
}

src_test() {
	sb_foreach_abi sb_test
}

sb_install() {
	emake DESTDIR="${D}" install || die
	insinto /etc/sandbox.d #333131
	doins etc/sandbox.d/00default || die
}

src_install() {
	sb_foreach_abi sb_install

	doenvd "${FILESDIR}"/09sandbox

	keepdir /var/log/sandbox
	fowners root:portage /var/log/sandbox
	fperms 0770 /var/log/sandbox

	cd "${S}"
	dodoc AUTHORS ChangeLog* NEWS README
}

pkg_preinst() {
	chown root:portage "${D}"/var/log/sandbox
	chmod 0770 "${D}"/var/log/sandbox

	local old=$(find "${ROOT}"/lib* -maxdepth 1 -name 'libsandbox*')
	if [[ -n ${old} ]] ; then
		elog "Removing old sandbox libraries for you:"
		elog ${old//${ROOT}}
		find "${ROOT}"/lib* -maxdepth 1 -name 'libsandbox*' -exec rm -fv {} \;
	fi
}

pkg_postinst() {
	chmod 0755 "${ROOT}"/etc/sandbox.d #265376
}
