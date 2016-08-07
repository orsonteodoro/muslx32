# muslx32
This is an unofficial muslx32 (musl libc and x32 abi) overlay for Gentoo Linux

This profile uses a 64-bit linux kernel with x32 abi compatibility.  All of the userland libraries and programs are built as native x32 ABI without duplicate 64-bit and 32-bit versions (a.k.a. multilib).

Current goals:  get popular packages and necessary developer tools working on the platform/profile for widespread adoption.

Why musl and x32 and Gentoo?  Musl because it is lightweight.  X32 because it reduces memory usage.  Alpine Linux, an embedded mini distro, had Firefox tagging my USB for many tabs resulting in a big slow down.  I was really disappointed about Alpine and the shortcomings of the other previously tested distros.  It was many times slower than the RAM based distros such as Linux Mint and Slax, so there was a motivation to work on muslx32 for Gentoo.  Tiny Linux and Slax packages were pretty much outdated.  blueness said that he wouldn't make muslx32 as top priority or it wasn't his job to do or after the hardened gcc patches for the platform were ready, so I decided to just do it myself without the hardened part.

What is x32?  x32 ABI is 32-bit (4-bytes) per integer, long, pointer using all of the x86_64 general purpose registers identified as (rax,rbx,rcx,r11-r15,rsi,rdi) and using sse registers.  Long-long integers are 8 bytes.  C/C++ programs will use __ILP32__ preprocessor checks to distinguish between 32/64 bit systems.  The build system may also compare void* to see if it has __x86_64__ defined and 4 bytes for 32-bit for 8 bytes for 64-bit for LP64 (longs are 8 bytes as well as pointers).

Disadvantages of this platform:  No binary packages work (e.g. spotify, genymotion, virtualbox, etc.) since no major distro currently completely supports it.  Some SIMD assembly optimizations are not enabled.  Some assembly based packages don't work because they need to be hand edited.  It is not multilib meaning that there may be problems with packages that only offer x86 or x86_64 like wine [which has no x32 support].

Other recommendations?  Use -Os and use kernel zswap+zbud to significantly reduce swapping.  Use cache to ram for Firefox if using Gentoo from a usbstick.

You need use crossdev to build this.  Crossdev is used to build the cross-compile toolchain.  Use the cross-compile toolchain to build system.  Use the system to build world.  The result is a stage 3/4 image like the tarball you download from Gentoo.  It sounds easy but there are a lot of broken ebuilds and packages that need patches.  It took me several weeks to get it right.  I give you the overlay this time, so it will only take you a few days.

Some patches for musl libc and x32 came from Alpine Linux (Natanael Copa), Void Linux, debian x32 port (Adam Borowski), musl overlay (Anthony G. Basile/blueness), musl-extras (Aric Belsito/lluixhi)) .... (will update this list)

What you can do to help?:  
-Clean the ebuilds with proper x32 abi and musl chost checks and submit them to Gentoo.
-Write assembly code for the jit based packages and assembly based packages.
-Test and patch new ebuilds for these use cases: server, web, gaming, etc, entertainment, developer.
-Fix the build system to get rid of the bashrc script and odd quirks.

Expected Repositories and priorities (negative less important and positive is highest ebuilds used):

gentoo
    location: /usr/portage
    sync-type: rsync
    sync-uri: rsync://rsync.gentoo.org/gentoo-portage
    priority: -1000

musl
    location: /var/lib/layman/musl
    masters: gentoo
    priority: 0

musl-extras (optional; https://github.com/lluixhi/musl-extras)
    location: /usr/local/musl-extras
    masters: gentoo
    priority: 1

muslx32
    location: /usr/local/muslx32 <--- this repository
    masters: gentoo
    priority: 2

x-portage
    location: /usr/local/portage
    masters: gentoo
    priority: 3

Works:
-firefox 45.x only - except when using alsa audio and jit.  javascript works but through interpreter.  pulseaudio untested.
-strace (for debugging) from this overlay
-gdb (for debugging) from this overlay
-X (for windowing system)
-wpa_supplicant (for wifi)
-xf86-video-nouveau
-xf86-video-ati
*see bottom of readme for details emerged packages
-mplayer (but without simd optimizations)
-mpd
-geany
-dwm
-xfce4
-aterm from this overlay
-xfce4-terminal
-gimp
-xscreensaver
-glxgears from mesa-progs

Broken (do not use the ebuild and associated patches from this overlay if broken.  my personal patches may add more complications so do it from scratch again): 
-Makefile.in or make system - use my bashrc scripts to fix it see below.
-Chromium (v8 javascript engine is broken for x32.  Intel V8 X32 team (Chih-Ping
Chen, Dale Schouten, Haitao Feng, Peter Jensen and Weiliang Lin) were working on it in May 2013-Jun 2014, but it has been neglected and doesn't work since the testing of >=52.0.2743.116 of Chromium.
-wayland (dunno)
-weston (segfaults)
-pulseaudio (cannot connect pavucontrol or pulseaudio apps)
-webkit-gtk just blank screen, jit is broken it works for 2.0.4 but it doesn't work when applied to 2.12.3. 2.0.4. is unstable and crashes out a lot.  Yuqiang Xian of Intel was working on it but stopped in Apr 2013.
-evdev (semi broken and quirky; dev permissions need to be manually set or devices reloaded)
-grub2-install (doesn't work in x32 use lilo)
-xterm (works in root but not as user)
-mono C# (incomplete patch from PLD Linux... was testing) details (https://www.mail-archive.com/pld-cvs-commit@lists.pld-linux.org/msg361561.html) on what needs to be done.
-chrony and ntp or musl's timezone stuff is broken.  use the hw clock instead.  do not automatically update time though ntp protocol
-import (from imagematick) - cannot take a screenshot use imlib2 
-clang - cannot compile it yet

Unconfirmed broken:
revdep-rebuild - it always says linking is fine.

Masks:
>sys-libs/ncurses-5.9-r5

The following need to be cross-compiled and may interrupt emerge -e system.  
if your native compiles fail, build these as cross-compiled:
dev-libs/mpfr
sys-devel/gettext
sys-apps/which

----cutnpaste

#bashrc script
#This is the contents of /etc/portage/bashrc script to fix Makefile.in/libtool/Automake system.  Add this before running emerge.
#Use only MAKEOPTS="-j1" .  Some packages may be able to get away with MAKEOPTS="-j5" or whatever or system can handle.

if [[ "${CATEGORY}/${PN}" != "sys-scheme/guile" ]]; then #this if bay be disabled/removed

if [[ $EBUILD_PHASE == configure ]]; then
	einfo "Applying automake/libtool musl patch"
	for file in $(find "${WORKDIR}" -name "Makefile" -o -name "Makefile.in" -o -name "Makefile.in.in" -o -name "Make-in"); do
		einfo "Editing $file"

		local myallrecursive
		local myinstallrecursive

		myallrecursive=""
		grep -q "all-recursive" $file
		[[ "$?" == "0" ]] && myallrecursive="all-recursive"

		myinstallrecursive=""
		grep -q "install-recursive" $file
		[[ "$?" == "0" ]] && myinstallrecursive="install-recursive"

		#einfo "Applying automake musl patch"
		grep -q "\$(am__cd) \$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target" "$file"
		[[ "$?" == "0" ]] && sed -i 's|(\$(am__cd) \$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target) |$(am__cd) $(CURDIR)/$$subdir \&\& $(MAKE) $(AM_MAKEFLAGS) $$local_target |g' "$file"
		
		grep -q "\$(am__cd) \$(srcdir)/\$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target" "$file"
		[[ "$?" == "0" ]] && sed -i 's|\$(am__cd) \$(srcdir)/\$\$subdir && \$(MAKE) \$(AM_MAKEFLAGS) \$\$local_target |$(am__cd) $(CURDIR)/$$subdir \&\& $(MAKE) $(AM_MAKEFLAGS) $$local_target |g' "$file"

		grep -q "all-am" $file
		[[ "$?" == "0" ]] && sed -i -e ':a' -e 'N' -e '$!ba' -e 's|\nall: all-recursive\n|\nall: all-recursive all-am\n|g' "$file"

		grep -q "all-am" $file
		[[ "$?" == "0" ]] && sed -i -e ':a' -e 'N' -e '$!ba' -e "s|\nall: \$(BUILT_SOURCES)\n|\nall: \$(BUILT_SOURCES) ${myallrecursive} all-am\n|g" "$file"

		grep -q "all-am" $file
		[[ "$?" == "0" ]] && sed -i -e ':a' -e 'N' -e '$!ba' -e "s|\nall: \$(BUILT_SOURCES) config.h\n|\nall: \$(BUILT_SOURCES) config.h ${myallrecursive} all-am\n|g" "$file"

		grep -q "install-am" $file
	        [[ "$?" == "0" ]] && sed -i -e ':a' -e 'N' -e '$!ba' -e 's|\ninstall: install-recursive\n|\ninstall: install-recursive install-am\n|g' "$file"

		grep -q "install-am" $file
		[[ "$?" == "0" ]] && sed -i -e ':a' -e 'N' -e '$!ba' -e "s|\ninstall: \$(BUILT_SOURCES)\n|\ninstall: ${myinstallrecursive} \$(BUILT_SOURCES) install-am\n|g" "$file"

		if [[ $file =~ "/po/" && $file =~ "Makefile.in.in" ]]; then
			sed -i -e ':a' -e 'N' -e '$!ba' -e "s|\nall: \([-a-zA-Z ]*\)all-@USE_NLS@\n\n|\nall: \1 ${myallrecursive} all-@USE_NLS@\nall-am:\ninstall-am:\n\n|g" "$file"
		fi

		if [[ $file =~ "/po/" && $file =~ "Make-in" ]]; then
			sed -i -e ':a' -e 'N' -e '$!ba' -e "s|\nall: all-@USE_NLS@\n\n|\nall: ${myallrecursive} all-@USE_NLS@\nall-am:\ninstall-am:\ninfo-am:\n\n|g" "$file"
		fi

		grep -q "\$\$files" "$file"
		if [[ "$?" == "0" ]]; then
			#einfo "Applying libtool musl patch"
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's|if test -f "\$(CURDIR)/\$\$p"; then d="\$(CURDIR)/"\; else d="\$(srcdir)/"\; fi\; \\|if [[ -f "$(CURDIR)/$$p" ]]\; then \\\n\t    d="$(CURDIR)/"\; \\\n\telif [[ -f "$(srcdir)/$$p" ]]\; then \\\n\t    d="$(srcdir)/"\; \\\n\telif [[ -f "$$p" ]]; then \\\n\t    d=""\; \\\n\tfi\; \\|g' "$file"
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's|if test -f \$\$p\; then d=\; else d="\$(srcdir)\/"\; fi\; \\\n\t  echo "\$\$d\$\$p"\; echo "\$\$\p"\; \\|if [[ -f "$(CURDIR)/$$p" ]]; then \\\n\t    d="$(CURDIR)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$(srcdir)/$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$$p" ]]; then \\\n\t    echo "$$p"; \\\n\t  fi; \\|g' "$file"
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's|for p in \$\$list\; do \\\n\t  if test -f "\$\$p"\; then d=\; else d="\$(srcdir)\/"\; fi\; \\\n\t  echo "\$$d\$\$p"\; \\|for p in $$list; do \\\n\t  if [[ -f "$(CURDIR)/$$p" ]]; then \\\n\t    d="$(CURDIR)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$(srcdir)/$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$d$$p"; \\\n\t  elif [[ -f "$$p" ]]; then \\\n\t    d="$(srcdir)/"; \\\n\t    echo "$$p"; \\\n\t  fi; \\|g' "$file"
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's|echo " \$(\([-_a-zA-Z0-9]*\)) \$\$files \x27\$(DESTDIR)\$(\([-_a-zA-Z0-9]*\))\x27"\; \\\n\t  \$([-_a-zA-Z0-9]*) \$\$files "\$(DESTDIR)\$([-_a-zA-Z0-9]*)" \|\| exit \$\$?\; \\|if \[\[ -d "$$files" \|\| -z "$$files" \]\]\; then \\\n\t    continue; \\\n\t  fi; \\\n\t  echo " $(\1) $$files \x27$(DESTDIR)$(\2)\x27"; \\\n\t  $(\1) $$files "$(DESTDIR)$(\2)" \|\| exit $$?; \\|g' "$file"	
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's|test -z "\$\$files" \|\| { echo " \$(\([-_a-zA-Z0-9]*\)) \$(srcdir)\/\$\$files \x27\$(DESTDIR)\$(\([-_a-zA-Z0-9]*\))\x27"\; \\\n\t  \$([-_a-zA-Z0-9]*) \$(srcdir)\/\$\$files "\$(DESTDIR)\$([-_a-zA-Z0-9]*)" \|\| exit \$\$?\; }\; \\|if \[\[ -d "$$files" \|\| -z "$$files" \]\]\; then \\\n\t    continue; \\\n\t  fi; \\\n\t  echo " $(\1) $$files \x27$(DESTDIR)$(\2)\x27"; \\\n\t  $(\1) $$files "$(DESTDIR)$(\2)" \|\| exit $$?; \\|g' "$file"	
	                sed -i -e ':a' -e 'N' -e '$!ba' -e 's|test -z "\$\$files" \|\| { \\\n\t    echo " \$(\([-_a-zA-Z0-9]*\)) \$\$files \x27\$(DESTDIR)\$(\([-_a-zA-Z0-9]*\))\x27"\; \\\n\t    \$([-_a-zA-Z0-9]*) \$\$files "\$(DESTDIR)\$([-_a-zA-Z0-9]*)" \|\| exit \$\$?\; }\; \\|if \[\[ -d "$$files" \|\| -z "$$files" \]\]\; then \\\n\t    continue; \\\n\t  fi; \\\n\t  echo " $(\1) $$files \x27$(DESTDIR)$(\2)\x27"; \\\n\t  $(\1) $$files "$(DESTDIR)$(\2)" \|\| exit $$?; \\|g' "$file"
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's|echo " \$(INSTALL_SCRIPT) \$\$files \x27\$(DESTDIR)\$(bindir)\$\$dir\x27"\; \\|if [[ -z "$$files" \|\| -d "$$files" ]]; then \\\n\t\t   continue; \\\n\t       fi; \\\n\t       echo " $(INSTALL_SCRIPT) $$files \x27$(DESTDIR)$(bindir)$$dir\x27"; \\|g' "$file"	
		fi

		grep -q "CTAGS = ctags" "$file"
		if [[ "$?" == "0" ]]; then
			sed -i "s|CTAGS = ctags|CTAGS = true|g" "$file"
		fi

		grep -q "SOURCES = " "$file"
		if [[ "$?" == "0" ]]; then
			sed -i -e ':a' -e 'N' -e '$!ba' -e "s|\nall-am: Makefile \$(LTLIBRARIES) \$(DATA) \$(HEADERS) config.h\n|\nall-am: Makefile \$(SOURCES) \$(LTLIBRARIES) \$(DATA) \$(HEADERS) config.h\n|g" "$file"
		fi
	done
fi

fi


----cutnpaste

These are the instructions to build stage 4 image from a 1 to 3 cross compile toolchain, system cross-compiled toolchain (x86_64-pc-muslx32-emerge -e system), system native toolchain (emerge -e system), and the world set (emerge -e world).  
These are incomplete instructions and may be out of order steps so backup!  Adjust these steps to your needs.


assuming sysrescuecd

setup wifi with nmtui

##################
# Partition device
#

repartition the drive
100M boot as ext4
4G swap as linux swap
*G root ext4

mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

#important turn on swap before compiling
swapon /dev/sda2

mount /dev/sda3 /mnt/gentoo
cd /mnt/gentoo
links gentoo.org

###################################
# Dump stage3 into system partition
#

get portage-latest from gentoo mirror
get current-stage3-x32 from gentoo mirror

unpack both

move portage into usr

cp /etc/resolv.conf /mnt/gentoo/etc
screen
chroot /mnt/gentoo /bin/bash

################
# Crossdev phase
#

emerge crossdev

emerge dev-vcs/git layman
layman -L
layman -

#this block is optional if you are using the muslx32 overlay
cd ~/
git clone http://github.com/GregorR/musl-gcc-patches.git
mkdir -p /usr/local/portage

mkdir -p /usr/local/muslx32
cd /usr/local/muslx32
git clone http://github.com/orsonteodoro/muslx32.git

add this muslx32 to overlay for crossdev and later to the cross system toolchain
edit /etc/portage/make.conf
add line: PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/local/portage"
add line: PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/local/muslx32"

cd /etc/portage
mv make.profile make.profile.orig
ln -s /usr/portage/profiles/hardened/linux/musl/amd64/x32 ./make.profile

This block is not necessary if you have the muslx32 overlay.  This is here for backup just in case my overlay fails.
mkdir -p /etc/portage/patches/cross-x86_64-pc-linux-muslx32/gcc
cp ~/musl-gcc-patches/*.diff /etc/portage/patches/cross-x86_64-pc-linux-muslx32/gcc
cd /etc/portage/patches/cross-x86_64-pc-linux-muslx32/gcc
for file in *.diff; do mv $file "`basename $file .diff`.patch"; done

cd /etc/portage/package.use
nano gcc
cross-x86_64-pc-linux-muslx32/gcc -sanitize -fortran -vtv
sys-devel/gcc -sanitize -fortran -vtv

crossdev -S -A x32 --g "=5.3.0" --target x86_64-pc-linux-muslx32

#################################################
# Post-crossdev phase / build cross toolchain
#

edit /etc/portage/make.conf
add line: source /var/lib/layman/make.conf

cd /usr/x86_64-pc-linux-muslx32/etc/portage
mv make.profile make.profile.orig
ln -s /usr/portage/profiles/hardened/linux/musl/amd64/x32 ./make.profile

cd /usr/x86_64-pc-linux-muslx32/etc/portage/package.use
nano gcc
cross-x86_64-pc-linux-muslx32/gcc -sanitize -fortran -vtv
sys-devel/gcc -sanitize -fortran -vtv

#add my bashrc script above to fix make and all the Makefile.in.  use only MAKEOPTS=-j1

#build the cross compile toolchain
x86_64-pc-linux-muslx32-emerge -pve system

#Required to fix emerge
#portage or musl screws this up by making /lib an actual folder when it should be just a symlink.  These next steps fix it.
cd /usr/x86_64-pc-linux-muslx32/
cp -a ./usr/lib ./usr/lib/libx32
rm ./usr/lib
ln -s ./usr/lib/libx32 ./usr/lib

#do the same for ./lib ./libx32
cp -a ./lib ./libx32
rm ./lib
ln -s ./libx32 ./lib

get the latest stable kernel from kernel.org instead
extract contents into /usr/x86_64-pc-linux-muslx32/usr/src
ln -s linux-4.6.1 linux
cd linux

cd /usr/x86_64-pc-linux-muslx32/usr/src/linux/

nano xkmake 
#add the following below:
#!/bin/sh
exec make ARCH="x86_64" CROSS_COMPILE="x86_64-pc-linux-muslx32-" INSTALL_MOD_PATH="${SYSROOT}" "$@"

chmod +x xkmake
emerge -1 bc             #compile time dependency for compiling kernel
./xkmake menuconfig      #choose options add squashfs, tmpfs, x32 support, wifi, sata driver
./xkmake                 #build bzImage and modules
mkdir /boot
mount /dev/sda1 /boot
cp /usr/x86_64-pc-linux-muslx32/usr/src/linux/arch/x86/boot/bzImage /boot
cp /usr/x86_64-pc-linux-muslx32/usr/src/linux/System.map /boot
cp /usr/x86_64-pc-linux-muslx32/usr/src/linux/.config /boot

#you can use these make.conf.cross make.conf.native or the ones provided at the end of the readme
cp /usr/x86_64-pc-linux-muslx32/etc/portage/make.conf /usr/x86_64-pc-linux-muslx32/etc/portage/make.conf.cross
cp /etc/portage/make.conf /usr/x86_64-pc-linux-muslx32/etc/portage/make.conf.native #copy the catalyst makefile
cd /usr/x86_64-pc-linux-muslx32/etc/portage
ln -s make.conf.native make.conf

cd /usr/x86_64-pc-linux-muslx32
mkdir proc
mkdir dev

#add missing dev
cd dev
mknod console c 0 0
mknod -m 666 null c 1 3
mknod -m 666 zero c 1 5

cd /usr/x86_64-pc-linux-muslx32
#this should be done before any chroot
mount -t proc proc proc
mount --bind /dev ./   #urandom fix

cp /usr/bin/python-wrapper /usr/x86_64-pc-linux-muslx32/usr/bin #temporary workaround
mkdir -p /usr/x86_64-pc-linux-muslx32/etc/env.d/python
cd /usr/x86_64-pc-linux-muslx32/etc/env.d/python/config
nano config
#add line:
python2.7

cd /usr/x86_64-pc-linux-muslx32
#copy the resolv.conf to ./etc
chroot ./ /bin/bash

###############################################################################
# Post cross system toolchain phase (stage 3 image) / Build native toolchain
#

#Fix the settings in /etc/portage/make.conf.native before proceeding.
#An example make.conf.native is provided at the end of this readme.

#build the native toolchain
emerge -ve system

#Remember to build mpfr, which, gettext as cross-compile if it fails then continue `emerge --resume`  You will need to change  the symlink make.conf between make.conf.cross and make.conf.native and to exit and enter the chroot to switch between cross-compiled `x86_64-pc-linux-muslx32` and native `emerge`.  See bottom of page for contents of make.conf.cross and make.conf.native.

#Important
#Set the root password before reboot.  We are not rebooting yet.

#emerge lilo and use it
emerge lilo
cp /etc/lilo.conf.example /etc/lilo.conf
edit /etc/lilo.conf
remove/comment out the readonly
add line:
append = "init=/sbin/init zswap.enabled=1"
change to:
boot = /dev/sda
change to:
root = /dev/sda3
to install lilo run the command: lilo

######################################################################################################################
# Post native system toolchain phase (stage 4 image) / Customize image to use case (desktop,server,etc) or your needs
# You might consider skipping this phase and jump to the next phase.
#

#Fix the settings in /etc/portage/make.conf.native before proceeding.
#An example make.conf.native is provided at the end of this readme.

#Build the world
emerge -ve world

#Remember to build mpfr, which, gettext as cross-compile if it fails then continue `emerge --resume`  You will need to change  the symlink make.conf between make.conf.cross and make.conf.native and to exit and enter the chroot to switch between cross-compiled `x86_64-pc-linux-muslx32` and native `emerge`  See bottom of page for contents of make.conf.cross and make.conf.native.

#IMPORTANT
#Remember to set your root password and users before rebooting.  We are not rebooting yet.

add app-arch/gzip-1.7 to /usr/x86_64-pc-linux-muslx32/etc/package.accept_keywords

#add to package.use/wpa_supplicant
dev-util/pkgconfig internal-glib
sys-apps/help2man -nls

emerge wpa_supplicant #for wifi

#recommended for wifi
emerge wpa_supplicant
emerge dhcpcd
#emerge chrony #do not use broken
emerge wireless-tools
emerge nano #editor

#optional
emerge screen
emerge links

#unmount all mounted in /usr/x86_64-pc-linux-muslx32/mnt and /usr/x86_64-pc-linux-muslx32/boot
exit
exit
#unmount all mounted in /usr/mnt/gentoo


#alsa-sound needs permissions corrected because bugged evdev
#to fix add the following /etc/init.d/fixalsa
#do a     find /sys/devices -name "pcm*"         to find them all

#contents of /etc/init.d/fixalsa
#!/sbin/runscript
# Copyright (c) 2016 Orson Teodoro <orsonteodoro@yahoo.com>
# Released under MIT.

description="Fixing ALSA for non-root user"

depend()
{
	after udev
}

start()
{
	einfo "Fixing ALSA for non-root"
	udevadm test /sys/devices/pci*/*/sound/card0/controlC0 2&>1 >/dev/null
	udevadm test /sys/devices/pci*/*/sound/card0/pcmC0D0c 2&>1 >/dev/null
	udevadm test /sys/devices/pci*/*/sound/card0/pcmC0D0p 2&>1 >/dev/null
	udevadm test /sys/devices/pci*/*/sound/card0/pcmC0D1c 2&>1 >/dev/null
	udevadm test /sys/devices/pci*/*/sound/card0/pcmC0D1p 2&>1 >/dev/null
	return 0
}


#add fixalsa service
rc-update add fixalsa


#fix permissions for /dev/tty
#contents of /dev/init.d/fixtty
#!/sbin/runscript
# Copyright (c) 2016 Orson Teodoro <orsonteodoro@yahoo.com>
# Released under MIT.

description="Fixing tty permissions"

depend()
{
	need localmount
	after udev
}

start()
{
	einfo "Fixing tty permissions"
	chown root:tty /dev/pty*
	chmod 660 /dev/pty*

	chmod 666 /dev/ptmx

	chown root:tty /dev/tty*
	chmod 660 /dev/tty*

	chmod 666 /dev/null
	chmod 666 /dev/random
	chmod 666 /dev/urandom

	return 0
}

#rc-update add fixtty

#fix permissions for /dev/video
#contents of /dev/init.d/fixvideo
#!/sbin/runscript
# Copyright (c) 2016 Orson Teodoro <orsonteodoro@yahoo.com>
# Released under MIT.

description="Fixing video permissions"

depend()
{
	after localmount
}

start()
{
	einfo "Fixing video permissions"
	chown root:video /dev/dri/card*
	chmod 666 /dev/dri/card*
	return 0
}

#rc-update add fixvideo
#the 6 for others in chmod may need to be changed to 0

#remember to add users to video, audio, users

#for xkeyboard-config
ln -s /usr/lib/gcc/x86_64-pc-linux-muslx32/4.9.3/libgomp.so.1 /lib/libgomp.so.1
ln -s /usr/lib/gcc/x86_64-pc-linux-muslx32/4.9.3/libstdc++.so.6 /lib/libstdc++.so.6
#other softlinks may need to be created in /lib

#xorg.conf needs to be told explicity which modules to load.  It doesn't work the way it should with `X =configure` like with glibc under musl.

#contents of /etc/X11/xorg.conf.d/20-nouveau.conf
Section "Module"
	Load "exa"
	Load "wfb"
	Load "dri"
	Load "dri2"
	Load "dri3"
	Load "int10"
	Load "vbe"
	Load "fb"
	Load "shadowfb"
	Load "shadow"
	Load "vgahw"
	Load "evdev"
	Load "keyboard"
	Load "mouse"
	Load "fbdevhw"
	Load "glamoregl"
	Load "glx"
#	Load "ati_drv"
	Load "radeon_drv"
#	Load "nouveau_drv"
#	Load "vesa_drv"
#	Load "modesetting_drv"
EndSection

Section "ServerLayout"
	Identifier	"Layout0"
	Screen	0       "Screen0"
	InputDevice     "Keyboard0" "CoreKeyboard"
	InputDevice     "Mouse0" "CorePointer"
	Option "AutoAddDevices" "False"
EndSection

Section "InputDevice"
	Identifier	"Mouse0"
	Driver		"mouse"
	Option		"Protocol" "auto"
	Option		"Device" "/dev/input/mice"
	Option		"ZAxisMapping" "4 5"
	Option		"XAxisMapping" "6 7"
	Option		"Buttons" "17"
EndSection

Section "InputDevice"
	Identifier	"Keyboard0"
	Driver		"kbd"
EndSection

# the right one
Section "Monitor"
          Identifier   "Samsung 941BW"
          Option "PreferredMode" "1440x900_60.00"
	  Option "UseEdidDpi" "FALSE"
	  HorizSync 30.0-81.0
	  VertRefresh  56.0-75.0
	  Option "DPI" "96 x 96"
#	  Option "DMPS"
EndSection

#pixel clock 137MHz
#1440x900@75Hz max
#1440x900@60Hz opti
# the left one
#Section "Monitor"
#          Identifier   "FUS"
#          Option "PreferredMode" "1280x1024_60.00"
#          Option "LeftOf" "NEC"
#EndSection

Section "Device"
#    Identifier "Nvidia"
    Identifier "ATI"
    Driver "radeon"
#    Driver "nouveau"
#    Driver "vesa"
#     Driver "modesetting"
    Option  "Monitor-DVI-I-1" "Samsung 941BW"
#    Option  "Monitor-DVI-I-2" "FUS"
#    Option "DRI3" "1"
    Option "AccelMethod" "glamor"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "Samsung"
    DefaultDepth 24
      SubSection "Display"
      Depth      24
#       Virtual 2560 2048
      Modes "1440x900" "" "1024x768" "800x600" "640x480"
      EndSubSection
#    Device "Nvidia"
    Device "ATI"
EndSection

----

###################################
# Last step.  Replace old tarball stage3 image with your native muslx32 image
# We are going to use the created native world image produced by you ground up replacing the unpacked official tarball image.
#This is the last confusing step.
#Do this correctly or expect to do this all over.
#You could create a snapshot of the system before proceeding.  Restore if you mess up.
#Also, make sure you have a working usbstick in case you need to fix lilo or bootloader.

#Now for the the tricky part.
#You can bork your system if you get it wrong and need to start from scratch again
#This step should only be done when thinks are final and you are sure that you want to reboot into this.
#In general, we put old files into trash and move the cross compiled stuff in root.
mkdir trash
mv * trash
mv trash/usr/x86_64-pc-linux-muslx32/* ./
#Do not delete the trash because you may need it later to build the 3 cross-compiled files.

#You may need to reverse theese steps if you feel the need to cross compile or too lazy to change the symlinks or your make.conf.

sync

reboot

----
#end of tutorial

emerge --info
Portage 2.2.28 (python 3.4.3-final-0, hardened/linux/musl/amd64/x32, gcc-4.9.3, musl-1.1.14, 4.4.6-gentoo x86_64)
=================================================================
System uname: Linux-4.4.6-gentoo-x86_64-AMD_Phenom-tm-_9850_Quad-Core_Processor-with-gentoo-2.2
KiB Mem:     4044808 total,   1262112 free
KiB Swap:    4095996 total,   4056120 free
Timestamp of repository gentoo: Thu, 04 Aug 2016 17:00:01 +0000
sh bash 4.3_p42-r1
ld GNU ld (Gentoo 2.25.1 p1.1) 2.25.1
ccache version 3.2.4 [enabled]
app-shells/bash:          4.3_p42-r1::gentoo
dev-lang/perl:            5.20.2::gentoo
dev-lang/python:          2.7.10-r1::gentoo, 3.4.3-r1::gentoo
dev-util/ccache:          3.2.4::gentoo
dev-util/cmake:           3.3.1-r1::gentoo
dev-util/pkgconfig:       0.28-r2::x-portage
sys-apps/baselayout:      2.2::gentoo
sys-apps/openrc:          0.19.1::gentoo
sys-apps/sandbox:         2.10-r99::x-portage
sys-devel/autoconf:       2.13::gentoo, 2.69::gentoo
sys-devel/automake:       1.11.6-r1::x-portage, 1.14.1::x-portage, 1.15::x-portage
sys-devel/binutils:       2.25.1-r1::gentoo
sys-devel/gcc:            4.9.3::gentoo
sys-devel/gcc-config:     1.7.3::gentoo
sys-devel/libtool:        2.4.6::x-portage
sys-devel/make:           4.1-r1::gentoo
sys-kernel/linux-headers: 4.3-r99::musl (virtual/os-headers)
sys-libs/musl:            1.1.14::x-portage
Repositories:

gentoo
    location: /usr/portage
    sync-type: rsync
    sync-uri: rsync://rsync.gentoo.org/gentoo-portage
    priority: -1000

musl
    location: /var/lib/layman/musl
    masters: gentoo
    priority: 0

oiledmachine-overlay
    location: /usr/local/oiledmachine-overlay
    masters: gentoo
    priority: 1

x-portage
    location: /usr/local/portage
    masters: gentoo
    priority: 2

ACCEPT_KEYWORDS="amd64"
ACCEPT_LICENSE="* -@EULA"
CBUILD="x86_64-pc-linux-muslx32"
CFLAGS="-O2 -pipe"
CHOST="x86_64-pc-linux-muslx32"
CONFIG_PROTECT="/etc"
CONFIG_PROTECT_MASK="/etc/ca-certificates.conf /etc/dconf /etc/env.d /etc/fonts/fonts.conf /etc/gconf /etc/gentoo-release /etc/revdep-rebuild /etc/sandbox.d /etc/terminfo"
CXXFLAGS="-O2 -pipe"
DISTDIR="/usr/portage/distfiles"
FCFLAGS="-O2 -pipe"
FEATURES="assume-digests binpkg-logs buildpkg ccache config-protect-if-modified distlocks ebuild-locks fixlafiles merge-sync news parallel-fetch preserve-libs protect-owned sandbox sfperms strict unknown-features-warn unmerge-logs unmerge-orphans userfetch userpriv usersandbox usersync xattr"
FFLAGS="-O2 -pipe"
GENTOO_MIRRORS="http://distfiles.gentoo.org"
INSTALL_MASK="charset.alias"
LDFLAGS="-Wl,-O1 -Wl,--as-needed"
MAKEOPTS="-j1"
PKGDIR="/usr/portage/packages"
PORTAGE_CONFIGROOT="/"
PORTAGE_RSYNC_OPTS="--recursive --links --safe-links --perms --times --omit-dir-times --compress --force --whole-file --delete --stats --human-readable --timeout=180 --exclude=/distfiles --exclude=/local --exclude=/packages --exclude=/.git"
PORTAGE_TMPDIR="/var/tmp"
USE="amd64 bindist cli cracklib crypt cxx dri fortran iconv ipv6 mmx modules ncurses nls nptl openmp pam pcre pic readline seccomp session sse sse2 ssl tcpd unicode xattr zlib" ABI_X86="x32" ALSA_CARDS="emu10k1" APACHE2_MODULES="authn_core authz_core socache_shmcb unixd actions alias auth_basic authn_alias authn_anon authn_dbm authn_default authn_file authz_dbm authz_default authz_groupfile authz_host authz_owner authz_user autoindex cache cgi cgid dav dav_fs dav_lock deflate dir disk_cache env expires ext_filter file_cache filter headers include info log_config logio mem_cache mime mime_magic negotiation rewrite setenvif speling status unique_id userdir usertrack vhost_alias" CALLIGRA_FEATURES="kexi words flow plan sheets stage tables krita karbon braindump author" CAMERAS="ptp2" COLLECTD_PLUGINS="df interface irq load memory rrdtool swap syslog" CPU_FLAGS_X86="3dnow 3dnowext mmx mmxext sse sse2 sse3" ELIBC="musl" GPSD_PROTOCOLS="ashtech aivdm earthmate evermore fv18 garmin garmintxt gpsclock itrax mtk3301 nmea ntrip navcom oceanserver oldstyle oncore rtcm104v2 rtcm104v3 sirf superstar2 timing tsip tripmate tnt ublox ubx" INPUT_DEVICES="keyboard mouse evdev" KERNEL="linux" LCD_DEVICES="bayrad cfontz cfontz633 glk hd44780 lb216 lcdm001 mtxorb ncurses text" LIBREOFFICE_EXTENSIONS="presenter-console presenter-minimizer" OFFICE_IMPLEMENTATION="libreoffice" PHP_TARGETS="php5-5" PYTHON_SINGLE_TARGET="python2_7" PYTHON_TARGETS="python2_7 python3_4" RUBY_TARGETS="ruby20 ruby21" USERLAND="GNU" VIDEO_CARDS="nouveau radeon r600" XTABLES_ADDONS="quota2 psd pknock lscan length2 ipv4options ipset ipp2p iface geoip fuzzy condition tee tarpit sysrq steal rawnat logmark ipmark dhcpmac delude chaos account"
Unset:  CC, CPPFLAGS, CTARGET, CXX, EMERGE_DEFAULT_OPTS, LANG, LC_ALL, PORTAGE_BUNZIP2_COMMAND, PORTAGE_COMPRESS, PORTAGE_COMPRESS_FLAGS, PORTAGE_RSYNC_EXTRA_OPTS, USE_PYTHON

----

Packages merged in:
These are the packages that would be merged, in order:

Calculating dependencies  .... .. ...... done!
[ebuild   R    ] app-arch/xz-utils-5.2.2::x-portage  USE="nls threads -static-libs" 0 KiB
[ebuild   R    ] sys-libs/ncurses-5.9-r5:0/5::gentoo  USE="cxx unicode (-ada) -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace" 0 KiB
[ebuild   R    ] virtual/libintl-0-r2::gentoo  0 KiB
[ebuild   R    ] dev-lang/python-exec-2.0.2:2::gentoo  PYTHON_TARGETS="(python2_7) (python3_3) (python3_4) (python3_5) (-jython2_7) (-pypy) (-pypy3)" 0 KiB
[ebuild   R    ] dev-libs/expat-2.1.1-r2::gentoo  USE="unicode -examples -static-libs" 0 KiB
[ebuild   R    ] virtual/libiconv-0-r2::gentoo  0 KiB
[ebuild   R    ] app-arch/bzip2-1.0.6-r7::gentoo  USE="-static -static-libs" 0 KiB
[ebuild   R    ] sys-devel/gnuconfig-20151214::gentoo  0 KiB
[ebuild   R    ] sys-apps/gentoo-functions-0.10::gentoo  0 KiB
[ebuild   R   ~] app-arch/gzip-1.7::gentoo  USE="pic -static" 0 KiB
[ebuild   R    ] app-misc/mime-types-9::gentoo  0 KiB
[ebuild   R    ] app-misc/c_rehash-1.7-r1::gentoo  0 KiB
[ebuild   R    ] sys-libs/gdbm-1.11-r99::musl  USE="nls -berkdb -exporter -static-libs" 0 KiB
[ebuild   R    ] sys-apps/which-2.21::gentoo  0 KiB
[ebuild   R    ] sys-apps/baselayout-2.2::gentoo  USE="-build" 0 KiB
[ebuild   R    ] sys-apps/debianutils-4.7::gentoo  USE="-static" 0 KiB
[ebuild   R    ] sys-apps/install-xattr-0.5::gentoo  0 KiB
[ebuild   R    ] net-libs/libmnl-1.0.3-r1::gentoo  USE="-examples -static-libs" 0 KiB
[ebuild   R    ] app-misc/editor-wrapper-4::gentoo  0 KiB
[ebuild   R    ] sys-devel/gcc-config-1.7.3::gentoo  0 KiB
[ebuild   R    ] sys-libs/musl-1.1.14::x-portage  0 KiB
[ebuild   R    ] app-text/manpager-1::gentoo  0 KiB
[ebuild   R    ] app-arch/unzip-6.0_p20::gentoo  USE="unicode -bzip2 -natspec" 0 KiB
[ebuild   R    ] dev-util/gperf-3.0.4::gentoo  0 KiB
[ebuild   R    ] dev-qt/qtchooser-0_p20151008::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] app-text/sgml-common-0.6.3-r5::gentoo  0 KiB
[ebuild   R    ] media-libs/libogg-1.3.1::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] sys-devel/automake-wrapper-10::gentoo  0 KiB
[ebuild   R    ] media-libs/libmpdclient-2.10::gentoo  USE="-doc -examples -static-libs" 0 KiB
[ebuild   R    ] sys-devel/autoconf-wrapper-13::gentoo  0 KiB
[ebuild   R    ] media-fonts/dejavu-2.34::gentoo  USE="-X -fontforge" 0 KiB
[ebuild   R    ] dev-libs/libyaml-0.1.6::gentoo  USE="-doc -examples -static-libs {-test}" 0 KiB
[ebuild   R    ] dev-libs/lzo-2.08:2::gentoo  USE="-examples -static-libs" 0 KiB
[ebuild   R    ] media-libs/vo-aacenc-0.1.3::gentoo  USE="-examples (-neon) -static-libs" 0 KiB
[ebuild   R    ] dev-util/re2c-0.13.7.5::gentoo  0 KiB
[ebuild   R    ] sys-devel/bin86-0.16.21::gentoo  0 KiB
[ebuild   R    ] dev-util/boost-build-1.56.0::x-portage  USE="-examples -python {-test}" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] media-libs/giflib-4.1.6-r3::gentoo  USE="-X -rle -static-libs" 0 KiB
[ebuild   R    ] dev-libs/libdaemon-0.14-r2::gentoo  USE="-doc -examples -static-libs" 0 KiB
[ebuild   R    ] net-libs/libasyncns-0.8-r3::gentoo  USE="-debug -doc" 0 KiB
[ebuild   R    ] sys-apps/tcp-wrappers-7.6.22-r99::musl  USE="ipv6 -netgroups -static-libs" 0 KiB
[ebuild   R    ] app-arch/cpio-2.12-r1::gentoo  USE="nls" 0 KiB
[ebuild   R    ] net-wireless/wireless-regdb-20160610::gentoo  0 KiB
[ebuild   R    ] dev-libs/tinyxml-2.6.2-r2::gentoo  USE="stl -debug -doc -static-libs" 0 KiB
[ebuild   R    ] dev-util/unifdef-2.10::gentoo  0 KiB
[ebuild   R    ] sys-kernel/linux-firmware-20160331::gentoo  USE="-savedconfig" 0 KiB
[ebuild   R    ] net-wireless/rfkill-0.5::gentoo  0 KiB
[ebuild   R    ] sys-apps/hdparm-9.48::gentoo  USE="-static" 0 KiB
[ebuild   R    ] sys-devel/binutils-config-5-r2::gentoo  0 KiB
[ebuild   R    ] virtual/libc-0::gentoo  0 KiB
[ebuild   R    ] sys-apps/net-tools-1.60_p20141019041918-r99::musl  USE="nls -old-output (-selinux) -static" 0 KiB
[ebuild   R    ] sys-devel/m4-1.4.17::x-portage  USE="-examples" 0 KiB
[ebuild   R    ] dev-libs/gobject-introspection-common-1.46.0::gentoo  0 KiB
[ebuild   R    ] dev-libs/libltdl-2.4.6::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] dev-libs/vala-common-0.30.1::gentoo  0 KiB
[ebuild   R    ] app-arch/zip-3.0-r3::gentoo  USE="crypt unicode -bzip2 -natspec" 0 KiB
[ebuild   R    ] virtual/ttf-fonts-1::gentoo  0 KiB
[ebuild   R    ] app-dicts/myspell-en-20160201::gentoo  0 KiB
[ebuild   R    ] sys-boot/lilo-24.1::musl  USE="-device-mapper -minimal -pxeserial -static" 0 KiB
[ebuild     U  ] sys-libs/timezone-data-2016e::gentoo [2016d::gentoo] USE="nls -leaps_timezone" 497 KiB
[ebuild   R    ] dev-libs/gmp-6.0.0a::gentoo  USE="cxx -doc -pgo -static-libs" 0 KiB
[ebuild   R    ] dev-libs/mpfr-3.1.3_p4::x-portage  USE="-static-libs" 0 KiB
[ebuild   R    ] dev-libs/mpc-1.0.2-r1::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-base/xorg-drivers-1.17::gentoo  INPUT_DEVICES="evdev keyboard mouse -acecad -aiptek -elographics -fpit -hyperpen -joystick (-libinput) -mutouch -penmount -synaptics -tslib (-vmmouse) -void -wacom" VIDEO_CARDS="nouveau radeon -amdgpu -apm -ast -chips -cirrus -dummy -epson -fbdev (-fglrx) (-freedreno) (-geode) -glint -i128 -i740 -intel -mach64 -mga -neomagic -nv (-nvidia) (-omap) (-omapfb) -qxl -r128 -radeonsi -rendition -s3 -s3virge -savage -siliconmotion -sisusb (-sunbw2) (-suncg14) (-suncg3) (-suncg6) (-sunffb) (-sunleo) (-suntcx) -tdfx (-tegra) -tga -trident -tseng -vesa (-via) (-virtualbox) (-vmware) (-voodoo)" 0 KiB
[ebuild   R    ] virtual/pam-0-r1::gentoo  0 KiB
[ebuild   R    ] virtual/libffi-3.0.13-r1::gentoo  0 KiB
[ebuild   R    ] virtual/os-headers-0::gentoo  0 KiB
[ebuild   R    ] sys-apps/sysvinit-2.88-r9::gentoo  USE="(-ibm) (-selinux) -static" 0 KiB
[ebuild   R    ] virtual/udev-215::gentoo  USE="(-systemd)" 0 KiB
[ebuild   R    ] sys-fs/udev-init-scripts-27::gentoo  0 KiB
[ebuild   R    ] virtual/dev-manager-0::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-python-20140125-r1::gentoo  0 KiB
[ebuild   R    ] virtual/shadow-0::gentoo  0 KiB
[ebuild   R    ] virtual/pkgconfig-0-r1::gentoo  0 KiB
[ebuild   R    ] sys-libs/readline-6.3_p8-r2::gentoo  USE="-static-libs -utils" 0 KiB
[ebuild   R    ] net-firewall/iptables-1.4.21-r99::musl  USE="ipv6 -netlink -static-libs" 0 KiB
[ebuild   R    ] dev-libs/libpipeline-1.4.0::gentoo  USE="-static-libs {-test}" 0 KiB
[ebuild   R   ~] dev-libs/libparserutils-0.2.3:0/0.2.3::gentoo  USE="iconv -debug -static-libs {-test}" 0 KiB
[ebuild   R   ~] dev-libs/libwapcaplet-0.3.0:0/0.3.0::gentoo  USE="-debug -static-libs {-test}" 0 KiB
[ebuild   R   ~] dev-libs/libutf8proc-1.3.1_p2:0/1.3.1_p2::gentoo  USE="-debug -static-libs" 0 KiB
[ebuild   R   ~] media-libs/librosprite-0.1.2-r1::gentoo  USE="-debug -static-libs" 0 KiB
[ebuild   R   ~] dev-libs/libnsutils-0.0.2:0/0.0.2::gentoo  USE="-debug -static-libs" 0 KiB
[ebuild   R   ~] media-libs/libnsgif-0.1.3::gentoo  USE="-debug -static-libs" 0 KiB
[ebuild   R   ~] media-libs/libnsbmp-0.1.3-r1:0/0.1.3::gentoo  USE="-debug -static-libs" 0 KiB
[ebuild   R    ] media-sound/mpc-0.27::gentoo  USE="iconv" 0 KiB
[ebuild   R    ] net-misc/dhcpcd-6.10.1::gentoo  USE="embedded ipv6 udev" 0 KiB
[ebuild   R    ] sys-apps/ifplugd-0.28-r9::x-portage  USE="-doc (-selinux)" 0 KiB
[ebuild   R   ~] net-libs/libhubbub-0.3.3:0/0.3.3::gentoo  USE="-debug -doc -static-libs {-test}" 0 KiB
[ebuild   R   ~] dev-libs/libcss-0.6.0:0/0.6.0::gentoo  USE="-debug -static-libs {-test}" 0 KiB
[ebuild   R    ] net-misc/netifrc-0.2.2::gentoo  0 KiB
[ebuild   R    ] virtual/jpeg-0-r2::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] virtual/perl-ExtUtils-MakeMaker-6.980.0::gentoo  0 KiB
[ebuild   R    ] app-text/docbook-xsl-stylesheets-1.79.0::gentoo  USE="-ruby" 0 KiB
[ebuild   R    ] virtual/opengl-7.0-r1::gentoo  0 KiB
[ebuild   R    ] media-libs/glu-9.0.0-r1::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] virtual/glu-9.0-r1::gentoo  0 KiB
[ebuild   R    ] app-text/docbook-xml-dtd-4.1.2-r6:4.1.2::gentoo  0 KiB
[ebuild   R    ] app-text/build-docbook-catalog-1.19.1::gentoo  0 KiB
[ebuild   R    ] app-text/docbook-xml-dtd-4.2-r2:4.2::gentoo  0 KiB
[ebuild   R    ] app-text/docbook-xml-dtd-4.4-r2:4.4::gentoo  0 KiB
[ebuild   R    ] app-text/docbook-xml-dtd-4.3-r1:4.3::gentoo  0 KiB
[ebuild   R    ] virtual/libudev-215-r1:0/1::gentoo  USE="-static-libs (-systemd)" 0 KiB
[ebuild   R    ] virtual/perl-MIME-Base64-3.140.0-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Scalar-List-Utils-1.380.0::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-opengl-1.3.1-r4::gentoo  0 KiB
[ebuild   R    ] virtual/freedesktop-icon-theme-0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-File-Spec-3.480.100-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Exporter-5.710.0-r2::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Compress-Raw-Zlib-2.65.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Digest-MD5-2.530.0-r2::gentoo  0 KiB
[ebuild   R    ] virtual/perl-version-0.990.900-r2::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Parse-CPAN-Meta-1.441.400-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-CPAN-Meta-YAML-0.12.0-r1::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-lib-bin-symlink-0.1.1::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-mpg123-0.1::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-notify-send-0.1::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-wxwidgets-20140423::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Time-Local-1.230.0-r3::gentoo  0 KiB
[ebuild   R    ] virtual/perl-IO-1.310.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Encode-2.600.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Carp-1.330.100::gentoo  0 KiB
[ebuild   R    ] virtual/perl-IO-Compress-2.64.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-libnet-1.270.0::gentoo  0 KiB
[ebuild   R    ] virtual/libgudev-230::gentoo  USE="-introspection -static-libs" 0 KiB
[ebuild   R    ] app-eselect/eselect-ruby-20131227::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Data-Dumper-2.154.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-JSON-PP-2.273.0-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-File-Temp-0.230.400-r4::gentoo  0 KiB
[ebuild   R    ] app-admin/perl-cleaner-2.20::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-fontconfig-1.1::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-mesa-0.0.10::gentoo  0 KiB
[ebuild   R    ] app-eselect/eselect-qtgraphicssystem-1.1.1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Storable-2.490.100-r1::gentoo  0 KiB
[ebuild   R    ] virtual/ffmpeg-9-r2::gentoo  USE="encode -X -gsm -jpeg2k -libav -mp3 -opus -sdl -speex -theora -threads -truetype -vaapi (-vdpau) (-x264)" 0 KiB
[ebuild   R    ] virtual/perl-parent-0.228-r1::gentoo  0 KiB
[ebuild   R    ] virtual/jpeg-62:62::gentoo  0 KiB
[ebuild   R    ] virtual/notification-daemon-0::gentoo  USE="-gnome" 0 KiB
[ebuild   R    ] virtual/perl-Digest-SHA-5.880.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Text-ParseWords-3.290.0-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Test-Harness-3.330.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Perl-OSType-1.7.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Module-Metadata-1.0.26::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Getopt-Long-2.420.0-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-ExtUtils-ParseXS-3.240.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-ExtUtils-Manifest-1.630.0-r2::gentoo  0 KiB
[ebuild   R    ] virtual/perl-ExtUtils-Install-1.670.0::gentoo  0 KiB
[ebuild   R    ] virtual/perl-ExtUtils-CBuilder-0.280.217-r2::gentoo  0 KiB
[ebuild   R    ] virtual/perl-CPAN-Meta-2.150.1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-CPAN-Meta-Requirements-2.125.0-r1::gentoo  0 KiB
[ebuild   R    ] sys-apps/sed-4.2.1-r1::x-portage  USE="nls -acl (-selinux) -static" 0 KiB
[ebuild   R    ] x11-themes/hicolor-icon-theme-0.15::gentoo  0 KiB
[ebuild   R    ] net-wireless/wireless-tools-30_pre9::gentoo  USE="-multicall" LINGUAS="-cs -fr" 0 KiB
[ebuild   R    ] sys-libs/zlib-1.2.8-r1::gentoo  USE="minizip -static-libs" 0 KiB
[ebuild   R    ] dev-libs/libpcre-8.38-r1:3::gentoo  USE="cxx readline recursion-limit (unicode) zlib -bzip2 -jit -libedit -pcre16 -pcre32 -static-libs" 0 KiB
[ebuild   R    ] sys-apps/kmod-22::gentoo  USE="tools zlib -debug -doc -lzma -python -static-libs" PYTHON_TARGETS="python2_7 python3_4 -python3_3" 0 KiB
[ebuild   R    ] sys-apps/file-5.25::gentoo  USE="zlib -python -static-libs" PYTHON_TARGETS="python2_7 python3_4 (-pypy) -python3_3" 0 KiB
[ebuild   R    ] sys-libs/cracklib-2.9.6::gentoo  USE="nls zlib -python -static-libs {-test}" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] dev-lang/perl-5.20.2:0/5.20::gentoo  USE="-berkdb -debug -doc -gdbm -ithreads" 0 KiB
[ebuild   R    ] media-libs/libpng-1.6.21:0/16::gentoo  USE="apng (-neon) -static-libs" 0 KiB
[ebuild   R    ] media-libs/tiff-4.0.6::gentoo  USE="cxx zlib -jbig -jpeg -lzma -static-libs {-test}" 0 KiB
[ebuild   R    ] media-libs/libmng-2.0.2-r1:0/2::gentoo  USE="-lcms -static-libs" 0 KiB
[ebuild   R    ] dev-libs/boost-1.56.0-r1:0/1.56.0::gentoo  USE="nls threads (-context) -debug -doc -icu -mpi -python -static-libs -tools" PYTHON_TARGETS="python2_7 python3_4 -python3_3" 0 KiB
[ebuild   R    ] dev-util/ccache-3.2.4::gentoo  0 KiB
[ebuild   R    ] sys-kernel/linux-headers-4.3-r99::musl  0 KiB
[ebuild   R    ] sys-apps/hwids-20150717-r1::gentoo  USE="net pci udev usb" 0 KiB
[ebuild   R    ] sys-apps/less-481::gentoo  USE="pcre unicode" 0 KiB
[ebuild   R    ] virtual/modutils-0::gentoo  0 KiB
[ebuild   R    ] sys-devel/autoconf-2.69:2.5::gentoo  USE="-emacs" 0 KiB
[ebuild   R    ] dev-util/gtk-doc-am-1.25::gentoo  0 KiB
[ebuild   R    ] sys-apps/help2man-1.46.6::gentoo  USE="-nls" 0 KiB
[ebuild   R    ] dev-perl/Module-Build-0.421.600::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-perl/URI-1.710.0::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-perl/HTTP-Date-6.20.0-r1::gentoo  0 KiB
[ebuild   R    ] media-libs/libwebp-0.4.0:0/5::gentoo  USE="jpeg png -experimental -gif -opengl -static-libs -swap-16bit-csp -tiff" 0 KiB
[ebuild   R    ] dev-perl/LWP-MediaTypes-6.20.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/XML-NamespaceSupport-1.110.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/XML-Parser-2.410.0-r2::gentoo  0 KiB
[ebuild   R    ] dev-lang/nasm-2.12.01::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] dev-perl/Encode-Locale-1.30.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/Digest-HMAC-1.30.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/HTML-Tagset-3.200.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/libintl-perl-1.240.0::gentoo  0 KiB
[ebuild   R    ] dev-perl/Text-Unidecode-0.40.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/Unicode-EastAsianWidth-1.330.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/IO-HTML-1.1.0::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-lang/swig-3.0.5::gentoo  USE="pcre -ccache -doc" 0 KiB
[ebuild   R    ] dev-perl/SGMLSpm-1.03-r7::gentoo  0 KiB
[ebuild   R    ] dev-perl/TermReadKey-2.330.0::gentoo  0 KiB
[ebuild   R    ] dev-perl/Text-CharWidth-0.40.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/XML-SAX-Base-1.80.0-r1::gentoo  0 KiB
[ebuild   R    ] virtual/perl-Compress-Raw-Bzip2-2.64.0::gentoo  0 KiB
[ebuild   R    ] perl-core/libnet-1.270.0::gentoo  USE="-sasl" 0 KiB
[ebuild   R    ] perl-core/Module-Metadata-1.0.26::gentoo  0 KiB
[ebuild   R    ] perl-core/Data-Dumper-2.154.0::gentoo  0 KiB
[ebuild   R    ] perl-core/CPAN-Meta-2.150.1::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] perl-core/JSON-PP-2.273.0::gentoo  0 KiB
[ebuild   R    ] perl-core/File-Temp-0.230.400-r1::gentoo  0 KiB
[ebuild   R    ] sys-libs/libseccomp-2.3.0::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] sys-apps/busybox-1.24.2-r99::musl  USE="ipv6 static -debug -livecd -make-symlinks -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog (-systemd)" 0 KiB
[ebuild   R    ] virtual/pager-0::gentoo  0 KiB
[ebuild   R    ] sys-devel/automake-1.15:1.15::x-portage  0 KiB
[ebuild   R    ] dev-perl/HTTP-Message-6.110.0::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] sys-libs/mtdev-1.1.5::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] media-libs/libjpeg-turbo-1.5.0::gentoo  USE="-java -static-libs" 0 KiB
[ebuild   R    ] dev-perl/HTML-Parser-3.710.0-r1::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-perl/File-BaseDir-0.30.0-r1::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] sys-devel/automake-1.14.1:1.14::x-portage  0 KiB
[ebuild   R    ] dev-perl/Authen-SASL-2.160.0-r1::gentoo  USE="-kerberos" 0 KiB
[ebuild   R    ] dev-perl/Error-0.170.240::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] sys-devel/automake-1.11.6-r1:1.11::x-portage  0 KiB
[ebuild   R    ] dev-perl/File-Listing-6.40.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/WWW-RobotRules-6.20.0::gentoo  0 KiB
[ebuild   R    ] dev-perl/Text-WrapI18N-0.60.0-r1::gentoo  0 KiB
[ebuild   R   ~] dev-util/strace-4.12::x-portage  USE="-aio -perl -static -unwind" 0 KiB
[ebuild   R    ] sys-apps/pciutils-3.4.1::gentoo  USE="kmod udev zlib -dns -static-libs" 0 KiB
[ebuild   R    ] app-misc/pax-utils-1.1.6::gentoo  USE="seccomp -caps -debug -python" 0 KiB
[ebuild   R    ] sys-devel/libtool-2.4.6:2::x-portage  USE="-vanilla" 0 KiB
[ebuild   R    ] dev-perl/HTTP-Cookies-6.10.0::gentoo  0 KiB
[ebuild   R    ] dev-perl/HTTP-Daemon-6.10.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/HTTP-Negotiate-6.10.0::gentoo  0 KiB
[ebuild   R    ] dev-perl/File-DesktopEntry-0.40.0-r1::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-db/sqlite-3.12.0:3::gentoo  USE="readline secure-delete -debug -doc -icu -static-libs -tcl {-test} -tools" 0 KiB
[ebuild   R    ] dev-libs/libffi-3.2.1::x-portage  USE="-debug -pax_kernel -static-libs {-test}" 0 KiB
[ebuild   R    ] sys-apps/groff-1.22.2::gentoo  USE="-X -examples" L10N="-ja" 0 KiB
[ebuild   R    ] sys-apps/kbd-2.0.3::gentoo  USE="nls pam {-test}" 0 KiB
[ebuild   R    ] sys-process/procps-3.3.11-r3:0/5::x-portage  USE="kill ncurses nls unicode -modern-top (-selinux) -static-libs (-systemd) {-test}" 0 KiB
[ebuild   R    ] sys-apps/sandbox-2.10-r99::x-portage  USE="(-multilib)" 0 KiB
[ebuild   R    ] x11-proto/xproto-7.0.28::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] media-fonts/font-util-1.3.1::gentoo  0 KiB
[ebuild   R    ] x11-proto/xextproto-7.3.0::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] media-libs/freetype-2.6.3-r1:2::gentoo  USE="adobe-cff bindist -X -bzip2 -debug -doc -fontforge -harfbuzz (-infinality) -png -static-libs -utils" 0 KiB
[ebuild   R    ] x11-proto/inputproto-2.3.1::gentoo  0 KiB
[ebuild   R    ] x11-misc/util-macros-1.19.0::gentoo  0 KiB
[ebuild   R    ] media-libs/alsa-lib-1.0.29::gentoo [1.0.29::x-portage] USE="-alisp -debug -doc -python" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] x11-proto/kbproto-1.0.7::gentoo  0 KiB
[ebuild   R    ] x11-proto/renderproto-0.11.1-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/xf86vidmodeproto-2.3.1-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/xineramaproto-1.2.1-r1::gentoo  0 KiB
[ebuild   R    ] x11-libs/xtrans-1.3.5::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] dev-libs/icu-57.1:0/57::gentoo  USE="-debug -doc -examples -static-libs" 0 KiB
[ebuild   R    ] x11-proto/glproto-1.4.17-r1::gentoo  0 KiB
[ebuild   R    ] media-libs/libvorbis-1.3.4::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-proto/videoproto-2.3.2::gentoo  0 KiB
[ebuild   R    ] x11-proto/damageproto-1.2.1-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/randrproto-1.5.0::gentoo  0 KiB
[ebuild   R    ] x11-proto/xf86driproto-2.1.1-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/dri2proto-2.8-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/fontsproto-2.1.3::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] x11-misc/xbitmaps-1.1.1::gentoo  0 KiB
[ebuild   R    ] x11-proto/compositeproto-0.4.2-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/recordproto-1.14.2-r1::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] x11-proto/xf86dgaproto-2.1-r2::gentoo  0 KiB
[ebuild   R    ] x11-libs/libpciaccess-0.13.4-r99::musl  USE="zlib -static-libs" 0 KiB
[ebuild   R    ] dev-libs/nspr-4.12::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] dev-libs/libpthread-stubs-0.3-r1::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] dev-libs/nettle-3.2:0/6::gentoo  USE="gmp -doc (-neon) -static-libs {-test}" CPU_FLAGS_X86="-aes" 0 KiB
[ebuild   R    ] media-libs/babl-0.1.12::gentoo  USE="(-altivec)" CPU_FLAGS_X86="mmx sse sse2" 0 KiB
[ebuild   R    ] media-sound/mpg123-1.22.4::gentoo  USE="ipv6 -alsa (-altivec) (-coreaudio) -int-quality -jack -nas -oss -portaudio -pulseaudio -sdl" CPU_FLAGS_X86="3dnow 3dnowext mmx sse" 0 KiB
[ebuild   R    ] media-sound/lame-3.99.5-r1::gentoo  USE="frontend -debug -mp3rtp -sndfile -static-libs" CPU_FLAGS_X86="mmx" 0 KiB
[ebuild   R    ] x11-proto/presentproto-1.0::gentoo  0 KiB
[ebuild   R    ] x11-proto/dri3proto-1.0::gentoo  0 KiB
[ebuild   R    ] x11-proto/resourceproto-1.2.0::gentoo  0 KiB
[ebuild   R    ] x11-proto/scrnsaverproto-1.2.2-r1::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] x11-proto/xf86miscproto-0.9.3::gentoo  0 KiB
[ebuild   R    ] media-libs/libsamplerate-0.1.8-r1::gentoo  USE="-sndfile -static-libs" 0 KiB
[ebuild   R    ] x11-proto/xf86bigfontproto-1.2.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-libs/check-0.9.11::gentoo  USE="-static-libs -subunit" 0 KiB
[ebuild   R    ] dev-libs/iniparser-3.1-r1::gentoo  USE="-doc -examples -static-libs" 0 KiB
[ebuild   R    ] dev-libs/json-c-0.12::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] dev-libs/libatomic_ops-7.4.2::gentoo  0 KiB
[ebuild   R    ] media-libs/speex-1.2_rc1-r2::gentoo  USE="-ogg -static-libs" CPU_FLAGS_X86="sse" 0 KiB
[ebuild   R    ] x11-proto/bigreqsproto-1.1.2::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] x11-proto/xf86rushproto-1.1.2-r1::gentoo  0 KiB
[ebuild   R    ] x11-proto/trapproto-3.4.3::gentoo  0 KiB
[ebuild   R    ] x11-proto/xcmiscproto-1.2.2::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] dev-util/pkgconfig-0.28-r2::x-portage  USE="internal-glib -hardened" 0 KiB
[ebuild   R    ] dev-util/ragel-6.7-r1::gentoo  USE="-vim-syntax" 0 KiB
[ebuild   R    ] net-ftp/ncftp-3.2.5-r3::gentoo  USE="ipv6 -pch" 0 KiB
[ebuild   R    ] media-libs/fontconfig-2.11.1-r2:1.0::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libICE-1.0.9::gentoo  USE="ipv6 -doc -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libdrm-2.4.65-r99::musl  USE="-libkms -static-libs -valgrind" VIDEO_CARDS="nouveau radeon -amdgpu (-exynos) (-freedreno) -intel (-omap) (-tegra) (-vmware)" 0 KiB
[ebuild   R    ] x11-libs/libXau-1.0.8::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/pixman-0.32.8::gentoo  USE="(-altivec) (-iwmmxt) (-loongson2f) (-neon) -static-libs" CPU_FLAGS_X86="mmxext sse2 -ssse3" 0 KiB
[ebuild   R    ] x11-libs/libfontenc-1.1.3::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] media-sound/alsa-utils-1.0.29:0.9::gentoo  USE="libsamplerate ncurses nls -doc (-selinux)" 0 KiB
[ebuild   R    ] x11-libs/libXdmcp-1.1.2::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] x11-proto/fixesproto-5.0-r1::gentoo  0 KiB
[ebuild   R    ] x11-libs/libxshmfence-1.2::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] app-portage/portage-utils-0.62::gentoo  USE="nls -static" 0 KiB
[ebuild   R    ] media-libs/libtheora-1.1.1-r1::gentoo  USE="encode -doc -examples -static-libs" 0 KiB
[ebuild   R    ] media-libs/libshout-2.3.1-r1::gentoo  USE="-speex -static-libs -theora" 0 KiB
[ebuild   R    ] x11-apps/rgb-1.0.6::gentoo  0 KiB
[ebuild   R    ] x11-misc/makedepend-1.0.5::gentoo  0 KiB
[ebuild   R    ] x11-apps/sessreg-1.1.0-r99::musl  0 KiB
[ebuild   R    ] dev-libs/nss-3.23::gentoo  USE="cacert nss-pem -utils" 0 KiB
[ebuild   R    ] x11-apps/mkfontscale-1.1.2::gentoo  0 KiB
[ebuild   R    ] x11-apps/iceauth-1.0.7::gentoo  0 KiB
[ebuild   R    ] x11-libs/libXfont-1.5.1::gentoo  USE="ipv6 -bzip2 -doc -static-libs -truetype" 0 KiB
[ebuild   R    ] media-fonts/font-alias-1.0.3-r1::gentoo  0 KiB
[ebuild   R    ] x11-apps/mkfontdir-1.0.7::gentoo  0 KiB
[ebuild   R    ] media-fonts/encodings-1.0.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/bdftopcf-1.0.5::gentoo  0 KiB
[ebuild   R    ] media-fonts/font-misc-cyrillic-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-adobe-utopia-75dpi-1.0.4::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-daewoo-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-arabic-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-misc-ethiopic-1.0.3::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-sun-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-cronyx-cyrillic-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-bitstream-speedo-1.0.2::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-adobe-utopia-100dpi-1.0.4::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-misc-meltho-1.0.3::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-bitstream-75dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-adobe-75dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-adobe-utopia-type1-1.0.4::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-bh-lucidatypewriter-75dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-bh-lucidatypewriter-100dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-bh-ttf-1.0.3::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-micro-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-adobe-100dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-schumacher-misc-1.1.2::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-jis-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-ibm-type1-1.0.3::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-bitstream-100dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-screen-cyrillic-1.0.4::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-cursor-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-xfree86-type1-1.0.4::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-winitzki-cyrillic-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-isas-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-bh-75dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-dec-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-sony-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-bitstream-type1-1.0.3::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-bh-type1-1.0.3::gentoo  USE="-X" 0 KiB
[ebuild   R    ] media-fonts/font-mutt-misc-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-misc-misc-1.1.2::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] media-fonts/font-bh-100dpi-1.0.3::gentoo  USE="nls -X" 0 KiB
[ebuild   R    ] dev-libs/openssl-1.0.2h-r2::gentoo  USE="asm bindist sslv3 tls-heartbeat zlib -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla" CPU_FLAGS_X86="sse2" 0 KiB
[ebuild   R    ] dev-lang/python-2.7.10-r1:2.7::gentoo  USE="ipv6 ncurses readline sqlite ssl threads (wide-unicode) xml (-berkdb) -build -doc -examples -gdbm -hardened -tk -wininst" 0 KiB
[ebuild   R    ] dev-lang/python-3.4.3-r1:3.4::gentoo  USE="ipv6 ncurses readline ssl threads xml -build -examples -gdbm -hardened -sqlite -tk -wininst" 0 KiB
[ebuild   R   #] net-misc/iputils-20160308::x-portage  USE="ipv6 openssl ssl -SECURITY_HAZARD -arping -caps -clockdiff -doc -filecaps -gcrypt -idn -libressl -nettle -rarpd -rdisc -static -tftpd -tracepath -traceroute" 0 KiB
[ebuild   R    ] dev-libs/libevent-2.0.22::gentoo  USE="ssl threads -debug -static-libs {-test}" 0 KiB
[ebuild   R    ] www-client/links-2.8-r1:2::gentoo  USE="ipv6 ssl unicode zlib -X -bzip2 -directfb -fbcon -gpm -jpeg -livecd -lzma (-suid) (-svga) -tiff" 0 KiB
[ebuild   R    ] dev-perl/Net-SSLeay-1.720.0-r1::gentoo  USE="-examples (-libressl) -minimal {-test}" 0 KiB
[ebuild   R    ] www-client/elinks-0.12_pre6-r1::x-portage  USE="ipv6 mouse nls ssl unicode zlib -X -bittorrent -bzip2 -debug -finger -ftp -gc -gopher -gpm -guile -idn -javascript -lua -nntp -perl -ruby -samba -xml" 0 KiB
[ebuild   R    ] app-misc/ca-certificates-20151214.3.21::gentoo  USE="cacert" 0 KiB
[ebuild   R    ] dev-libs/libxml2-2.9.4:2::gentoo  USE="icu ipv6 python readline -debug -examples -lzma -static-libs {-test}" PYTHON_TARGETS="python2_7 python3_4 -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] dev-perl/IO-Socket-SSL-2.24.0::gentoo  USE="-idn" 0 KiB
[ebuild   R    ] dev-libs/libevdev-1.4.4::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] dev-util/ninja-1.6.0::gentoo  USE="-doc -emacs {-test} -vim-syntax -zsh-completion" 0 KiB
[ebuild   R    ] dev-python/packaging-15.3-r2::gentoo  USE="{-test}" PYTHON_TARGETS="python2_7 python3_4 (-pypy) (-pypy3) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] net-misc/ntp-4.2.8_p8::gentoo  USE="ipv6 readline ssl threads -caps -debug (-libressl) -openntpd (-parse-clocks) -samba (-selinux) -snmp -vim-syntax -zeroconf" 0 KiB
[ebuild   R    ] sys-devel/gettext-0.19.7::x-portage  USE="cxx ncurses openmp -acl -cvs -doc -emacs -git -java (-nls) -static-libs" 0 KiB
[ebuild   R   ~] dev-libs/wayland-1.11.0::x-portage  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] dev-perl/Net-HTTP-6.90.0::gentoo  USE="-minimal" 0 KiB
[ebuild   R    ] x11-proto/xcb-proto-1.11::x-portage  PYTHON_TARGETS="python2_7 python3_4 -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] dev-perl/XML-SAX-0.990.0-r1::gentoo  0 KiB
[ebuild   R    ] dev-perl/Net-SMTP-SSL-1.30.0::gentoo  USE="{-test}" 0 KiB
[ebuild   R   ~] net-libs/libdom-0.3.0:0/0.3.0::gentoo  USE="xml -debug -expat -static-libs {-test}" 0 KiB
[ebuild   R    ] dev-util/itstool-2.0.2::gentoo  PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] dev-libs/libinput-1.3.0:0/10::x-portage  USE="{-test}" INPUT_DEVICES="-wacom" 0 KiB
[ebuild   R    ] sys-devel/make-4.1-r1::gentoo  USE="nls -guile -static" 0 KiB
[ebuild   R    ] sys-apps/attr-2.4.47-r999::musl  USE="nls -static-libs" 0 KiB
[ebuild   R    ] sys-apps/findutils-4.6.0-r1::x-portage  USE="nls -debug (-selinux) -static {-test}" 0 KiB
[ebuild   R    ] sys-apps/grep-2.25::x-portage  USE="nls pcre -static" 0 KiB
[ebuild   R    ] sys-apps/gawk-4.1.3::gentoo  USE="nls readline -mpfr" 0 KiB
[ebuild   R    ] app-arch/tar-1.28-r1::x-portage  USE="nls xattr -acl -minimal (-selinux) -static" 0 KiB
[ebuild   R    ] sys-process/psmisc-22.21-r2::x-portage  USE="ipv6 nls -X (-selinux)" 0 KiB
[ebuild   R    ] sys-libs/e2fsprogs-libs-1.42.13::gentoo  USE="nls -static-libs" 0 KiB
[ebuild   R    ] dev-libs/popt-1.16-r2::gentoo  USE="nls -static-libs" 0 KiB
[ebuild   R    ] app-editors/nano-2.5.3::gentoo  USE="magic ncurses nls spell unicode -debug -justify -minimal -slang -static" 0 KiB
[ebuild   R    ] sys-apps/diffutils-3.3::x-portage  USE="nls -static" 0 KiB
[ebuild   R    ] net-misc/wget-1.18::gentoo  USE="ipv6 nls pcre ssl zlib -debug -gnutls -idn (-libressl) -ntlm -static {-test} -uuid" 0 KiB
[ebuild   R    ] dev-util/intltool-0.51.0-r1::gentoo  0 KiB
[ebuild   R    ] sys-devel/flex-2.5.39-r1::gentoo  USE="nls -static {-test}" 0 KiB
[ebuild   R    ] dev-lang/yasm-1.2.0-r1::gentoo  USE="nls -python" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] sys-apps/texinfo-6.1::gentoo  USE="nls -static" 0 KiB
[ebuild   R    ] dev-vcs/git-2.7.3-r1::gentoo  USE="blksha1 curl iconv nls pcre perl python threads webdav -cgi -cvs -doc -emacs -gnome-keyring (-gpg) -gtk -highlight (-libressl) (-mediawiki) -mediawiki-experimental (-ppcsha1) -subversion {-test} -tk -xinetd" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] app-text/hunspell-1.3.3-r99::musl  USE="ncurses nls readline -static-libs" LINGUAS="-af -bg -ca -cs -cy -da -de -el -en -eo -es -et -fo -fr -ga -gl -he -hr -hu -ia -id -is -it -km -ku -lt -lv -mk -ms -nb -nl -nn -pl -pt -pt_BR -ro -ru -sk -sl -sq -sv -sw -tn -uk -zu" 0 KiB
[ebuild   R    ] net-dns/libidn-1.33::gentoo  USE="nls -doc -emacs -java -mono -static-libs" 0 KiB
[ebuild   R    ] app-text/iso-codes-3.68::gentoo  LINGUAS="-af -am -ar -as -ast -az -be -bg -bn -bn_IN -br -bs -byn -ca -crh -cs -cy -da -de -dz -el -en -eo -es -et -eu -fa -fi -fo -fr -ga -gez -gl -gu -haw -he -hi -hr -hu -hy -ia -id -is -it -ja -ka -kk -km -kn -ko -kok -ku -lt -lv -mi -mk -ml -mn -mr -ms -mt -nb -ne -nl -nn -nso -oc -or -pa -pl -ps -pt -pt_BR -ro -ru -rw -si -sk -sl -so -sq -sr -sr@latin -sv -sw -ta -te -th -ti -tig -tk -tl -tr -tt -tt@iqtelif -ug -uk -ve -vi -wa -wal -wo -xh -zh_CN -zh_HK -zh_TW -zu" 0 KiB
[ebuild   R    ] dev-scheme/guile-2.0.11:13::x-portage  USE="deprecated nls regex threads -debug -debug-freelist -debug-malloc -discouraged -emacs -networking" 0 KiB
[ebuild   R    ] media-libs/libexif-0.6.21-r1::gentoo  USE="nls -doc -static-libs" 0 KiB
[ebuild   R    ] sys-libs/binutils-libs-2.25.1-r2:0/2.25.1::gentoo  USE="nls zlib -64-bit-bfd -multitarget -static-libs" 0 KiB
[ebuild   R    ] media-libs/flac-1.3.1-r1::x-portage  USE="cxx (-altivec) -debug -ogg -static-libs" CPU_FLAGS_X86="-sse" 0 KiB
[ebuild   R   ~] dev-libs/wayland-protocols-1.4::gentoo  0 KiB
[ebuild   R    ] dev-perl/Locale-gettext-1.50.0-r1::gentoo  0 KiB
[ebuild   R    ] app-text/opensp-1.5.2-r3::gentoo  USE="nls -doc -static-libs {-test}" 0 KiB
[ebuild   R    ] dev-perl/XML-LibXML-2.12.100::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] sys-apps/coreutils-8.23::x-portage  USE="nls xattr -acl -caps -gmp -multicall (-selinux) -static -vanilla" 0 KiB
[ebuild   R    ] sys-devel/patch-2.7.5::gentoo  USE="xattr -static {-test}" 0 KiB
[ebuild   R    ] net-misc/rsync-3.1.2::gentoo  USE="iconv ipv6 xattr -acl -static -stunnel" 0 KiB
[ebuild   R    ] virtual/editor-0::gentoo  0 KiB
[ebuild   R    ] sys-devel/bison-3.0.4-r1::x-portage  USE="nls -examples -static {-test}" 0 KiB
[ebuild   R    ] sys-devel/bc-1.06.95-r1::gentoo  USE="readline -libedit -static" 0 KiB
[ebuild   R    ] sys-libs/libcap-2.24-r2::gentoo  USE="pam -static-libs" 0 KiB
[ebuild   R    ] sys-devel/autoconf-2.13:2.1::gentoo  0 KiB
[ebuild   R   ~] dev-libs/libgpg-error-9999::x-portage  USE="nls -common-lisp -static-libs" 0 KiB
[ebuild   R    ] sys-devel/autogen-5.18.4::x-portage  USE="-libopts -static-libs" 0 KiB
[ebuild   R    ] dev-libs/hyphen-2.8.8::oiledmachine-overlay  USE="-static-libs" 0 KiB
[ebuild   R    ] media-libs/libsndfile-1.0.26::gentoo  USE="-alsa -minimal -sqlite -static-libs {-test}" 0 KiB
[ebuild   R    ] media-libs/netpbm-10.66.00-r99::musl  USE="zlib -X -doc -jbig -jpeg -jpeg2k -png -rle -static-libs (-svga) -tiff -xml" CPU_FLAGS_X86="sse2" 0 KiB
[ebuild   R    ] media-libs/libvpx-1.5.0:0/3::gentoo  USE="postproc threads -doc -static-libs -svc {-test}" CPU_FLAGS_X86="-avx -avx2 -mmx -sse -sse2 -sse3 -sse4_1 -ssse3" 0 KiB
[ebuild   R    ] app-text/openjade-1.3.2-r6::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] dev-perl/XML-Simple-2.200.0-r1::gentoo  0 KiB
[ebuild   R    ] app-misc/screen-4.3.1-r1::gentoo  USE="pam -debug -multiuser -nethack (-selinux)" 0 KiB
[ebuild   R    ] app-admin/eselect-1.4.5::gentoo  USE="-doc -emacs -vim-syntax" 0 KiB
[ebuild   R    ] sys-apps/iproute2-4.4.0-r99::musl  USE="iptables ipv6 -atm -berkdb -minimal (-selinux)" 0 KiB
[ebuild   R    ] virtual/yacc-0::gentoo  0 KiB
[ebuild   R    ] dev-libs/libgcrypt-1.6.5:0/20::x-portage  USE="threads -doc -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libxkbcommon-0.5.0::gentoo  USE="-X -doc -static-libs {-test}" 0 KiB
[ebuild   R    ] dev-libs/libnl-3.2.27:3::gentoo  USE="-python -static-libs -utils" PYTHON_TARGETS="python2_7 python3_4 -python3_3" 0 KiB
[ebuild   R   ~] dev-lang/spidermonkey-1.8.5-r5:0/mozjs185::x-portage  USE="-debug -minimal -static-libs {-test}" 0 KiB
[ebuild   R    ] x11-misc/icon-naming-utils-0.8.90::gentoo  0 KiB
[ebuild   R    ] sys-boot/grub-2.02_beta2-r9:2/2.02_beta2-r9::gentoo  USE="fonts multislot nls themes -debug -device-mapper -doc -efiemu (-libzfs) -mount -sdl -static {-test} -truetype" GRUB_PLATFORMS="pc -coreboot -efi-32 -efi-64 -emu -ieee1275 -loongson -multiboot -qemu -qemu-mips -uboot -xen" 0 KiB
[ebuild   R    ] sys-devel/binutils-2.25.1-r1:2.25.1::gentoo  USE="cxx nls zlib -multitarget -static-libs {-test} -vanilla" 0 KiB
[ebuild   R    ] app-shells/bash-4.3_p42-r1::gentoo  USE="net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla" 0 KiB
[ebuild   R    ] dev-libs/libxslt-1.1.29::gentoo  USE="crypt -debug -examples -python -static-libs" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] dev-libs/libtasn1-4.5:0/6::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R   ~] dev-libs/nsgenbind-0.3:0/0.3::gentoo  USE="-debug" 0 KiB
[ebuild   R   *] sys-devel/gdb-9999::x-portage  USE="client nls python server -expat -lzma -multitarget {-test} -vanilla" PYTHON_SINGLE_TARGET="python2_7 -python3_3 -python3_4 -python3_5" PYTHON_TARGETS="python2_7 python3_4 -python3_3 -python3_5" 0 KiB
[ebuild   R    ] sys-devel/gcc-4.9.3:4.9.3::gentoo  USE="cxx nls nptl openmp (-altivec) (-awt) (-cilk) -debug -doc (-fixed-point) -fortran -gcj -go -graphite -hardened (-libssp) (-multilib) -nopie -nossp -objc -objc++ -objc-gc -regression-test (-sanitize) -vanilla (-vtv)" 0 KiB
[ebuild   R    ] x11-libs/libxcb-1.11.1:0/1.11.1::gentoo  USE="-doc (-selinux) -static-libs {-test} -xkb" 0 KiB
[ebuild   R    ] net-libs/gnutls-3.3.24::gentoo  USE="crywrap cxx nls openssl zlib (-dane) -doc -examples -guile -pkcs11 -static-libs {-test}" LINGUAS="-cs -de -en -fi -fr -it -ms -nl -pl -sv -uk -vi -zh_CN" 0 KiB
[ebuild   R    ] app-crypt/p11-kit-0.20.7::gentoo  USE="asn1 libffi trust -debug" 0 KiB
[ebuild   R    ] x11-misc/xdg-user-dirs-0.15::gentoo  USE="-gtk" 0 KiB
[ebuild   R    ] app-text/po4a-0.45-r3::gentoo  USE="{-test}" LINGUAS="-af -ca -cs -da -de -eo -es -et -eu -fr -hr -id -it -ja -kn -ko -nb -nl -pl -pt -pt_BR -ru -sl -sv -uk -vi -zh_CN -zh_HK" 0 KiB
[ebuild   R    ] sys-kernel/gentoo-sources-4.4.6:4.4.6::gentoo  USE="-build -experimental -kdbus -symlink" 0 KiB
[ebuild   R    ] app-text/xmlstarlet-1.6.1::gentoo  0 KiB
[ebuild   R    ] sys-apps/man-db-2.7.5::gentoo  USE="gdbm manpager nls zlib -berkdb (-selinux) -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libX11-1.6.3::gentoo  USE="ipv6 -doc -static-libs {-test}" 0 KiB
[ebuild   R    ] media-video/ffmpeg-2.8.6:0/54.56.56::gentoo  USE="aac alsa bzip2 encode gnutls gpl hardcoded-tables iconv mp3 network pic postproc threads zlib -X -aacplus (-altivec) -amr -amrenc (-armv5te) (-armv6) (-armv6t2) (-armvfp) -bluray -bs2b -cdio -celt -cpudetection -debug -doc -examples -faac -fdk -flite -fontconfig -frei0r -fribidi -gme -gsm -iec61883 -ieee1394 -jack -jpeg2k -ladspa -libass -libcaca (-libressl) -librtmp -libsoxr -libv4l -lzma (-mipsdspr1) (-mipsdspr2) (-mipsfpu) -modplug (-neon) -openal -opengl -openssl -opus -oss -pulseaudio -quvi -samba -schroedinger -sdl -snappy -speex -ssh -static-libs {-test} -theora -truetype -twolame -v4l -vaapi (-vdpau) -vorbis -vpx -wavpack -webp (-x264) -x265 -xcb -xvid -zvbi" CPU_FLAGS_X86="3dnow 3dnowext mmx mmxext sse sse2 sse3 -avx -avx2 -fma3 -fma4 -sse4_1 -sse4_2 -ssse3 -xop" FFTOOLS="aviocat cws2fws ffescape ffeval ffhash fourcc2pixfmt graph2dot ismindex pktdumper qt-faststart sidxindex trasher" 0 KiB
[ebuild   R    ] x11-libs/xcb-util-renderutil-0.3.9-r1::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] sys-devel/llvm-3.5.0-r99:0/3.5::x-portage  USE="libffi ncurses static-analyzer -clang -debug -doc -gold -libedit -multitarget -ocaml -python {-test} -xml" PYTHON_TARGETS="python2_7 (-pypy)" VIDEO_CARDS="radeon" 0 KiB
[ebuild   R    ] x11-apps/xlsatoms-1.1.2::gentoo  0 KiB
[ebuild   R    ] x11-libs/xcb-util-wm-0.4.1-r1::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] x11-libs/xcb-util-keysyms-0.4.0::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] virtual/man-0-r1::gentoo  0 KiB
[ebuild   R    ] x11-libs/libXext-1.3.3::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXrender-0.9.9::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXfixes-5.0.1::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libxkbfile-1.0.9::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-apps/xprop-1.2.2::gentoo  0 KiB
[ebuild   R    ] x11-apps/xwininfo-1.1.3::gentoo  0 KiB
[ebuild   R    ] x11-apps/xcmsdb-1.0.5::gentoo  0 KiB
[ebuild   R    ] x11-apps/xmodmap-1.0.9::gentoo  0 KiB
[ebuild   R    ] x11-apps/xrefresh-1.0.5::gentoo  0 KiB
[ebuild   R    ] x11-apps/luit-1.1.1::gentoo  0 KiB
[ebuild   R    ] x11-apps/xwud-1.0.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/xdriinfo-1.0.5::gentoo  0 KiB
[ebuild   R    ] x11-wm/dwm-6.1::gentoo  USE="-savedconfig -xinerama" 0 KiB
[ebuild   R    ] media-video/mplayer-1.2.1::gentoo  USE="alsa mp3 network -X -a52 -aalib (-altivec) (-aqua) -bidi -bl (-bluray) -bs2b -cddb -cdio -cdparanoia (-cpudetection) -debug -dga -directfb -doc -dts -dv -dvb -dvd -dvdnav -enca -encode -faac -faad -fbcon -ftp -ggi -gif -gsm -iconv -ipv6 -jack -joystick -jpeg -jpeg2k -ladspa -libass -libcaca -libmpeg2 -lirc -live -lzo -mad -md5sum -mng -nas -nut -openal -opengl -osdmenu -oss -png -pnm -pulseaudio -pvr -radio -rar -rtc -rtmp -samba -sdl (-selinux) -shm -speex -tga -theora -toolame -tremor -truetype -twolame -unicode -v4l -vcd (-vdpau) (-vidix) -vorbis (-x264) -xanim -xinerama -xscreensaver -xv -xvid -xvmc -yuv4mpeg -zoran" CPU_FLAGS_X86="-3dnow -3dnowext -mmx -mmxext -sse -sse2 -ssse3" VIDEO_CARDS="-mga -s3virge -tdfx" 0 KiB
[ebuild   R    ] x11-libs/libXi-1.7.5::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXcursor-1.1.14::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXrandr-1.5.0::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXft-2.3.2::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXcomposite-0.4.4-r1::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXdamage-1.1.4-r1::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXxf86vm-1.1.4::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-apps/xkbcomp-1.3.0::gentoo  0 KiB
[ebuild   R    ] x11-libs/libXv-1.0.10::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] media-libs/imlib2-1.4.9::gentoo  USE="X gif jpeg nls png zlib -bzip2 -doc -mp3 -static-libs -tiff" CPU_FLAGS_X86="mmx sse2" 0 KiB
[ebuild   R    ] x11-libs/libXinerama-1.1.3::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXres-1.0.7::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/libXxf86misc-1.0.3::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-apps/xkbevd-1.1.4::gentoo  0 KiB
[ebuild   R    ] x11-libs/libXxf86dga-1.1.4::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] media-libs/mesa-11.0.6::gentoo  USE="bindist classic dri3 egl gallium gbm gles2 llvm pic udev wayland -d3d9 -debug -gles1 (-nptl) -opencl (-openmax) -osmesa -pax_kernel (-selinux) -vaapi (-vdpau) -xa -xvmc" VIDEO_CARDS="nouveau r600 radeon (-freedreno) -i915 -i965 -ilo -intel -r100 -r200 -r300 -radeonsi (-vmware)" 0 KiB
[ebuild   R    ] x11-libs/libXtst-1.2.2::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] x11-misc/xkeyboard-config-2.16::x-portage  0 KiB
[ebuild   R    ] x11-apps/xcursorgen-1.0.6::gentoo  0 KiB
[ebuild   R    ] x11-misc/dmenu-4.6::gentoo  USE="-xinerama" 0 KiB
[ebuild   R    ] x11-terms/st-0.5::gentoo  USE="-savedconfig" 0 KiB
[ebuild   R    ] media-libs/giblib-1.2.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/xev-1.2.2::gentoo  0 KiB
[ebuild   R    ] x11-apps/xgamma-1.0.6::gentoo  0 KiB
[ebuild   R    ] x11-apps/xrandr-1.4.3::gentoo  0 KiB
[ebuild   R    ] x11-apps/xf86dga-1.0.3::gentoo  0 KiB
[ebuild   R    ] x11-apps/xinput-1.6.2::gentoo  0 KiB
[ebuild   R    ] x11-apps/xvinfo-1.1.3::gentoo  0 KiB
[ebuild   R    ] media-libs/libepoxy-1.3.1::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] x11-apps/xdpyinfo-1.3.2::gentoo  USE="-dga -dmx -xinerama" 0 KiB
[ebuild   R    ] x11-apps/setxkbmap-1.3.1::gentoo  0 KiB
[ebuild   R    ] x11-themes/xcursor-themes-1.0.4::gentoo  0 KiB
[ebuild   R    ] sys-libs/pam-1.2.1-r99::musl  USE="cracklib nls pie -audit -berkdb -debug -filecaps -nis (-selinux) {-test} -vim-syntax" 0 KiB
[ebuild   R    ] sys-auth/pambase-20150213::gentoo  USE="cracklib nullok sha512 -consolekit -debug -gnome-keyring -minimal -mktemp -pam_krb5 -pam_ssh -passwdqc -securetty (-selinux) (-systemd)" 0 KiB
[ebuild   R    ] sys-apps/util-linux-2.26.2::gentoo  USE="cramfs ncurses nls pam suid unicode -build -caps -fdformat -python (-selinux) -slang -static-libs (-systemd) {-test} -tty-helpers -udev" PYTHON_SINGLE_TARGET="python2_7 -python3_3 -python3_4" PYTHON_TARGETS="python2_7 python3_4 -python3_3" 0 KiB
[ebuild   R    ] sys-fs/e2fsprogs-1.42.13::gentoo  USE="(-nls) -static-libs" 0 KiB
[ebuild   R    ] sys-apps/openrc-0.19.1::gentoo  USE="ncurses netifrc pam unicode -audit -debug -newnet (-prefix) (-selinux) -static-libs -tools" 0 KiB
[ebuild   R    ] net-misc/openssh-7.2_p2::x-portage  USE="bindist pam pie ssl -X -X509 -debug -hpn -kerberos -ldap -ldns -libedit (-libressl) -sctp (-selinux) -skey -ssh1 -static" 0 KiB
[ebuild   R    ] sys-fs/eudev-3.1.5::gentoo  USE="hwdb kmod -introspection -rule-generator (-selinux) -static-libs {-test}" 0 KiB
[ebuild   R    ] sys-apps/shadow-4.1.5.1-r99::musl  USE="cracklib nls pam xattr -acl -audit (-selinux) -skey" 0 KiB
[ebuild   R    ] x11-libs/libSM-1.2.2-r1::gentoo  USE="ipv6 uuid -doc -static-libs" 0 KiB
[ebuild   R    ] app-text/xmlto-0.0.26-r1::gentoo  USE="text -latex" 0 KiB
[ebuild   R    ] virtual/ssh-0::gentoo  USE="-minimal" 0 KiB
[ebuild   R    ] virtual/service-manager-0::gentoo  USE="(-prefix)" 0 KiB
[ebuild   R    ] x11-libs/libXt-1.1.5::gentoo  USE="-static-libs" 0 KiB
[ebuild     U  ] app-arch/libarchive-3.2.1-r3:0/13::gentoo [3.1.2-r3:0/13::gentoo] USE="bzip2 e2fsprogs iconv lzma xattr zlib -acl -expat (-libressl) -lz4% -lzo -nettle -static-libs" 5322 KiB
[ebuild   R    ] sys-kernel/genkernel-3.4.52.3::gentoo  USE="-cryptsetup (-ibm) (-selinux)" 0 KiB
[ebuild   R    ] x11-libs/libXmu-1.1.2::gentoo  USE="ipv6 -doc -static-libs" 0 KiB
[ebuild   R    ] sys-apps/dbus-1.10.8-r1::gentoo  USE="X -debug -doc (-selinux) -static-libs (-systemd) {-test} -user-session" 0 KiB
[ebuild   R    ] dev-util/cmake-3.3.1-r1::gentoo  USE="ncurses -doc -emacs -qt4 -qt5 -system-jsoncpp {-test}" 0 KiB
[ebuild   R    ] x11-apps/appres-1.0.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/xwd-1.0.6::gentoo  0 KiB
[ebuild   R    ] x11-libs/libXpm-3.5.11::gentoo  USE="-static-libs" 0 KiB
[ebuild   R    ] x11-libs/fltk-1.3.3-r3:1::gentoo  USE="opengl threads xft xinerama -cairo -debug -doc -examples -games -static-libs" 0 KiB
[ebuild   R    ] media-gfx/feh-2.9.3::gentoo  USE="-curl -debug -exif {-test} -xinerama" 0 KiB
[ebuild   R    ] x11-terms/aterm-1.0.1-r2::x-portage  USE="-background -cjk -xgetdefault" 0 KiB
[ebuild   R    ] media-gfx/imagemagick-6.9.4.6:0/6.9.4.6::x-portage  USE="X cxx jpeg openmp png zlib -autotrace -bzip2 -corefonts -djvu -fftw -fontconfig -fpx -graphviz -hdri -jbig -jpeg2k -lcms -lqr -lzma (-opencl) -openexr -pango -perl -postscript -q32 -q64 -q8 -raw -static-libs -svg {-test} -tiff -truetype -webp -wmf -xml" 0 KiB
[ebuild   R    ] x11-apps/xrdb-1.1.0::gentoo  0 KiB
[ebuild   R    ] x11-apps/xauth-1.0.9-r2::gentoo  USE="ipv6" 0 KiB
[ebuild   R    ] media-gfx/graphite2-1.3.8::gentoo  USE="-perl {-test}" 0 KiB
[ebuild   R    ] x11-apps/xset-1.2.3::gentoo  0 KiB
[ebuild   R    ] x11-libs/libXaw-1.0.13::gentoo  USE="-deprecated -doc -static-libs" 0 KiB
[ebuild   R    ] net-libs/libproxy-0.4.13-r1::gentoo  USE="-gnome -kde -mono -networkmanager -perl -python -spidermonkey {-test} -webkit" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] x11-apps/x11perf-1.6.0::gentoo  0 KiB
[ebuild   R    ] x11-apps/xsetroot-1.1.1::gentoo  0 KiB
[ebuild   R    ] x11-apps/smproxy-1.0.6::gentoo  0 KiB
[ebuild   R    ] x11-apps/xpr-1.0.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/xkill-1.0.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/xhost-1.0.7::gentoo  USE="ipv6" 0 KiB
[ebuild   R    ] media-libs/glew-1.10.0-r2:0/1.10::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] www-client/dillo-3.0.5::gentoo  USE="gif ipv6 jpeg png ssl -doc" 0 KiB
[ebuild   R   ~] app-text/tidy-html5-5.2.0::gentoo  0 KiB
[ebuild   R    ] x11-apps/xinit-1.3.4-r1::gentoo  USE="minimal (-systemd)" 0 KiB
[ebuild   R    ] x11-apps/bitmap-1.0.8::gentoo  0 KiB
[ebuild   R    ] x11-apps/xkbutils-1.0.4::gentoo  0 KiB
[ebuild   R    ] x11-apps/mesa-progs-8.2.0::gentoo  USE="-egl -gles2" 0 KiB
[ebuild   R    ] x11-base/xorg-server-1.17.4:0/1.17.4::musl  USE="glamor ipv6 suid udev wayland xorg -dmx -doc -kdrive (-libressl) -minimal (-nptl) (-selinux) -static-libs (-systemd) -tslib -unwind -xephyr -xnest -xvfb" 0 KiB
[ebuild   R    ] x11-drivers/xf86-video-ati-7.5.0::gentoo  USE="glamor -udev" 0 KiB
[ebuild   R    ] x11-drivers/xf86-input-mouse-1.9.1::gentoo  0 KiB
[ebuild   R    ] x11-drivers/xf86-video-nouveau-1.0.11::gentoo  USE="glamor" 0 KiB
[ebuild   R    ] x11-drivers/xf86-input-evdev-2.9.2::gentoo  0 KiB
[ebuild   R    ] x11-drivers/xf86-input-keyboard-1.8.1::gentoo  0 KiB
[ebuild   R   #] dev-libs/glib-2.46.2-r3:2::x-portage  USE="dbus mime xattr -debug (-fam) (-selinux) -static-libs (-systemtap) {-test} -utils" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] x11-misc/shared-mime-info-1.4::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-util/desktop-file-utils-0.23::gentoo  USE="-emacs" 0 KiB
[ebuild   R    ] x11-libs/cairo-1.14.6::gentoo  USE="X glib opengl svg xcb (-aqua) -debug (-directfb) (-gles2) -static-libs -valgrind -xlib-xcb" 0 KiB
[ebuild   R    ] xfce-base/libxfce4util-4.12.1:0/7::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] dev-util/gdbus-codegen-2.46.2::gentoo  PYTHON_TARGETS="python2_7 python3_4 -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] dev-libs/dbus-glib-0.102::gentoo  USE="-debug -doc -static-libs {-test}" 0 KiB
[ebuild   R    ] app-text/enchant-1.6.0::gentoo  USE="hunspell -aspell -static-libs (-zemberek)" 0 KiB
[ebuild   R    ] net-libs/libqmi-1.12.6::gentoo  USE="-doc -static-libs" 0 KiB
[ebuild   R    ] dev-util/xfce4-dev-tools-4.12.0::gentoo  0 KiB
[ebuild   R    ] x11-themes/sound-theme-freedesktop-0.8::gentoo  0 KiB
[ebuild   R    ] media-sound/mpdscribble-0.22::gentoo  USE="curl" 0 KiB
[ebuild   R    ] media-sound/mpd-0.19.10::gentoo  USE="alsa curl ffmpeg glib lame libmpdclient mpg123 network -adplug -ao -audiofile -bzip2 -cdio -debug -eventfd -expat -faad -fifo -flac -fluidsynth -gme -icu -id3tag -inotify -ipv6 -jack -libav -libsamplerate -libsoxr -mad -mikmod -mms -modplug -musepack -nfs -ogg -openal -opus -oss -pipe -pulseaudio -recorder -samba (-selinux) -sid -signalfd -sndfile -soundcloud -sqlite (-systemd) -tcpd -twolame -unicode -upnp -vorbis -wavpack -wildmidi -zeroconf -zip -zlib" 0 KiB
[ebuild   R    ] dev-libs/gobject-introspection-1.46.0::gentoo  USE="-cairo (-doctool) {-test}" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] xfce-base/xfconf-4.12.0-r1::gentoo  USE="-debug -perl" 0 KiB
[ebuild   R    ] dev-libs/libsigc++-2.6.2:2::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] dev-libs/libcroco-0.6.11:0.6::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] gnome-base/dconf-0.24.0::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] dev-perl/File-MimeInfo-0.270.0::gentoo  USE="{-test}" 0 KiB
[ebuild   R    ] x11-libs/gnome-pty-helper-0.40.2::gentoo  USE="-hardened" 0 KiB
[ebuild   R    ] x11-themes/gnome-icon-theme-3.12.0::gentoo  USE="-branding" 0 KiB
[ebuild   R    ] dev-libs/libgudev-230::gentoo  USE="-debug -introspection -static-libs" 0 KiB
[ebuild   R   ~] dev-libs/weston-1.11.0::x-portage  USE="X drm gles2 jpeg launch resize-optimization suid wayland-compositor webp xwayland -colord -dbus -editor -examples -fbdev -headless -ivi -lcms -rdp (-rpi) -screen-sharing -static-libs (-systemd) {-test} -unwind" VIDEO_CARDS="-intel -v4l" 0 KiB
[ebuild   R    ] x11-libs/gdk-pixbuf-2.32.3:2::gentoo  USE="X introspection jpeg -debug -jpeg2k {-test} -tiff" 0 KiB
[ebuild   R    ] dev-libs/atk-2.18.0::gentoo  USE="introspection nls {-test}" 0 KiB
[ebuild   R    ] media-libs/gstreamer-1.6.3:1.0::x-portage  USE="caps introspection nls (-orc) {-test}" 0 KiB
[ebuild   R    ] media-libs/harfbuzz-1.2.7:0/0.9.18::x-portage  USE="cairo glib graphite icu introspection truetype -fontconfig -static-libs {-test}" 0 KiB
[ebuild   R    ] dev-cpp/glibmm-2.46.4:2::gentoo  USE="-debug -doc -examples {-test}" 0 KiB
[ebuild   R    ] dev-libs/json-glib-1.2.0::gentoo  USE="introspection -debug" 0 KiB
[ebuild   R    ] app-accessibility/at-spi2-core-2.18.3:2::gentoo  USE="introspection -X" 0 KiB
[ebuild   R    ] dev-cpp/cairomm-1.12.0-r1::gentoo  USE="X svg (-aqua) -doc" 0 KiB
[ebuild   R    ] gnome-base/gsettings-desktop-schemas-3.18.1::gentoo  USE="introspection" 0 KiB
[ebuild   R    ] net-misc/modemmanager-1.4.12-r99:0/1::musl  USE="introspection qmi -mbim -policykit -qmi-newest -vala" 0 KiB
[ebuild   R    ] x11-libs/libxklavier-5.3::gentoo  USE="introspection -doc" 0 KiB
[ebuild   R    ] x11-misc/xdg-utils-1.1.1::gentoo  USE="perl -doc" 0 KiB
[ebuild   R    ] x11-libs/pango-1.38.1::x-portage  USE="X introspection -debug {-test}" 0 KiB
[ebuild   R    ] dev-util/gtk-update-icon-cache-3.18.4::gentoo  0 KiB
[ebuild   R    ] x11-libs/libnotify-0.7.6-r3::gentoo  USE="introspection {-test}" 0 KiB
[ebuild   R    ] net-libs/glib-networking-2.46.1::gentoo  USE="gnome libproxy ssl -smartcard {-test}" 0 KiB
[ebuild   R    ] app-accessibility/at-spi2-atk-2.18.1:2::x-portage  USE="{-test}" 0 KiB
[ebuild   R    ] dev-cpp/atkmm-2.24.2::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] gnome-base/librsvg-2.40.15:2::gentoo  USE="introspection -tools -vala" 0 KiB
[ebuild   R    ] media-libs/gst-plugins-base-1.6.3:1.0::gentoo  USE="alsa introspection nls ogg pango theora vorbis -X -ivorbis (-orc)" 0 KiB
[ebuild   R    ] net-libs/libsoup-2.52.2:2.4::gentoo  USE="introspection ssl -debug -samba {-test} -vala" 0 KiB
[ebuild   R    ] media-libs/gegl-0.2.0-r2::gentoo  USE="-cairo -debug -ffmpeg -jpeg -jpeg2k -lensfun -libav -openexr -png -raw -sdl -svg -umfpack" CPU_FLAGS_X86="mmx sse" 0 KiB
[ebuild   R    ] dev-cpp/pangomm-2.38.1:1.4::gentoo  USE="-doc" 0 KiB
[ebuild   R    ] x11-libs/gtk+-2.24.30:2::gentoo  USE="introspection (-aqua) -cups -debug -examples {-test} -vim-syntax -xinerama" 0 KiB
[ebuild   R    ] app-misc/geoclue-2.4.3:2.0::gentoo  USE="introspection modemmanager -zeroconf" 0 KiB
[ebuild   R    ] media-libs/gst-plugins-bad-1.6.3:1.0::x-portage  USE="X introspection nls opengl -egl -gles2 -gtk (-orc) {-test} -vcd -vnc -wayland" 0 KiB
[ebuild   R    ] x11-themes/adwaita-icon-theme-3.18.0::gentoo  USE="-branding" 0 KiB
[ebuild   R    ] media-libs/gst-plugins-good-1.6.3:1.0::gentoo  USE="nls (-orc)" 0 KiB
[ebuild   R    ] media-plugins/gst-plugins-libav-1.6.3:1.0::gentoo  USE="-libav (-orc)" 0 KiB
[ebuild   R    ] x11-libs/gtk+-3.18.9:3::gentoo  USE="X introspection wayland (-aqua) -broadway -cloudprint -colord -cups -debug -examples {-test} -vim-syntax -xinerama" 0 KiB
[ebuild   R    ] x11-libs/libwnck-2.31.0:1::gentoo  USE="introspection -startup-notification" 0 KiB
[ebuild   R    ] gnome-base/libglade-2.6.4-r2:2.0::gentoo  USE="-static-libs {-test} -tools" PYTHON_SINGLE_TARGET="python2_7 (-pypy)" PYTHON_TARGETS="python2_7 (-pypy)" 0 KiB
[ebuild   R    ] x11-libs/vte-0.28.2-r207::musl  USE="introspection -debug -python" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] x11-themes/gtk-engines-xfce-3.2.0-r200::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] x11-libs/wxGTK-3.0.2.0-r2:3.0::gentoo  USE="X (-aqua) -debug -doc -gstreamer -libnotify -opengl -sdl -tiff -webkit" 0 KiB
[ebuild   R    ] net-irc/hexchat-2.10.2::gentoo  USE="gtk ipv6 nls plugins ssl -dbus -libcanberra -libnotify -libproxy -ntlm -perl -plugin-checksum -plugin-doat -plugin-fishlim -plugin-sysinfo -python -spell -theme-manager" PYTHON_SINGLE_TARGET="python2_7 -python3_3 -python3_4" PYTHON_TARGETS="python2_7 python3_4 -python3_3" 0 KiB
[ebuild   R    ] app-editors/leafpad-0.8.18.1::gentoo  USE="-emacs" 0 KiB
[ebuild   R    ] media-gfx/gimp-2.8.14-r2:2::gentoo  USE="exif jpeg png svg tiff -aalib -alsa (-altivec) (-aqua) -bzip2 -curl -dbus -debug -doc -gnome -jpeg2k -lcms -mng -pdf -postscript -python -smp {-test} -udev -webkit -wmf -xpm" CPU_FLAGS_X86="mmx sse" LINGUAS="-am -ar -ast -az -be -bg -br -ca -ca@valencia -cs -csb -da -de -dz -el -en_CA -en_GB -eo -es -et -eu -fa -fi -fr -ga -gl -gu -he -hi -hr -hu -id -is -it -ja -ka -kk -km -kn -ko -lt -lv -mk -ml -ms -my -nb -nds -ne -nl -nn -oc -pa -pl -pt -pt_BR -ro -ru -rw -si -sk -sl -sr -sr@latin -sv -ta -te -th -tr -tt -uk -vi -xh -yi -zh_CN -zh_HK -zh_TW" PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] xfce-base/libxfce4ui-4.12.1-r2::gentoo  USE="gtk3 -debug -startup-notification" 0 KiB
[ebuild   R    ] media-libs/libcanberra-0.30-r5::gentoo  USE="gtk gtk3 sound -alsa -gnome -gstreamer -oss -pulseaudio -tdb -udev" 0 KiB
[ebuild   R    ] x11-libs/gtksourceview-3.18.2:3.0/3::gentoo  USE="introspection -glade {-test} -vala" 0 KiB
[ebuild   R    ] app-crypt/gcr-3.18.0:0/1::gentoo  USE="gtk introspection -debug {-test} -vala" 0 KiB
[ebuild   R    ] dev-cpp/gtkmm-3.18.1:3.0::gentoo  USE="X wayland (-aqua) -doc -examples {-test}" 0 KiB
[ebuild   R    ] dev-util/geany-1.25::gentoo  USE="vte -gtk3" 0 KiB
[ebuild   R    ] net-ftp/filezilla-3.12.0.2::gentoo  USE="nls (-aqua) -dbus {-test}" 0 KiB
[ebuild   R   ~] www-client/netsurf-3.5::gentoo  USE="bmp duktape gif gtk javascript jpeg mng png rosprite svg webp -debug -fbcon -fbcon_frontend_able -fbcon_frontend_linux -fbcon_frontend_sdl -fbcon_frontend_vnc -fbcon_frontend_x -gstreamer -pdf-writer -svgtiny -truetype" 0 KiB
[ebuild   R    ] xfce-base/exo-0.10.6::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] xfce-base/garcon-0.5.0-r1::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] gnome-base/gvfs-1.26.3::gentoo  USE="http udev -afp -archive (-bluray) -cdda -fuse -gnome-keyring -gnome-online-accounts -google -gphoto2 -gtk -ios -mtp -nfs -samba (-systemd) {-test} -udisks -zeroconf" 0 KiB
[ebuild   R    ] x11-misc/notification-daemon-3.14.1::gentoo  0 KiB
[ebuild   R    ] x11-terms/xfce4-terminal-0.6.3::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] gnome-extra/gnome-calculator-3.18.3::gentoo  0 KiB
[ebuild   R    ] xfce-base/xfce4-panel-4.12.0::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] xfce-base/xfce4-settings-4.12.0::gentoo  USE="xklavier -debug -libcanberra -libinput -libnotify -upower" 0 KiB
[ebuild   R    ] xfce-base/xfce4-appfinder-4.12.0-r1::gentoo  USE="-debug" 0 KiB
[ebuild   R    ] xfce-base/xfwm4-4.12.3::gentoo  USE="dri xcomposite -debug -startup-notification" 0 KiB
[ebuild   R    ] xfce-base/thunar-1.6.10::gentoo  USE="dbus pcre -debug -exif -libnotify {-test} -udisks" XFCE_PLUGINS="trash" 0 KiB
[ebuild   R    ] xfce-base/xfdesktop-4.12.2::gentoo  USE="thunar -debug -libnotify" 0 KiB
[ebuild   R    ] dev-qt/qtcore-4.8.6-r99:4::x-portage  USE="exceptions glib iconv icu qt3support ssl (-aqua) -debug -pch" 0 KiB
[ebuild   R    ] dev-qt/qttest-4.8.6-r1:4::gentoo  USE="exceptions (-aqua) -debug -pch" 0 KiB
[ebuild   R    ] dev-qt/qttranslations-4.8.6-r1:4::gentoo  0 KiB
[ebuild   R    ] dev-qt/qtscript-4.8.6-r2:4::gentoo  USE="exceptions (-aqua) -debug (-jit) -pch" 0 KiB
[ebuild   R    ] dev-qt/qtsql-4.8.6-r1:4::gentoo  USE="exceptions qt3support sqlite (-aqua) -debug -freetds -mysql (-oci8) -odbc -pch -postgres" 0 KiB
[ebuild   R    ] dev-lang/ruby-2.1.9:2.1::gentoo  USE="ipv6 ncurses rdoc readline ssl -berkdb -debug -doc -examples -gdbm -rubytests -socks5 -xemacs" 0 KiB
[ebuild   R    ] dev-lang/ruby-2.0.0_p648:2.0::musl  USE="ipv6 ncurses rdoc readline ssl -berkdb -debug -doc -examples -gdbm -rubytests -socks5 -xemacs" CPU_FLAGS_X86="sse2" 0 KiB
[ebuild   R    ] dev-ruby/rubygems-2.2.5-r1::gentoo  USE="-server {-test}" RUBY_TARGETS="ruby20 ruby21 (-ruby19)" 0 KiB
[ebuild   R    ] virtual/rubygems-10::gentoo  RUBY_TARGETS="ruby20 ruby21 (-ruby19)" 0 KiB
[ebuild   R    ] dev-ruby/rake-0.9.6-r1::gentoo  USE="-doc {-test}" RUBY_TARGETS="ruby20 ruby21" 0 KiB
[ebuild   R    ] net-libs/webkit-gtk-2.12.3:4/37::x-portage  USE="(X) egl geoloc gstreamer introspection nsplugin opengl spell wayland webgl (-aqua) -bmalloc -coverage -doc -gles2 -gnome-keyring (-jit) {-test}" 0 KiB
[ebuild   R    ] dev-ruby/json-1.8.2-r1::gentoo  USE="-doc {-test}" RUBY_TARGETS="ruby20 ruby21" 0 KiB
[ebuild   R    ] dev-ruby/racc-1.4.11::gentoo  USE="-doc {-test}" RUBY_TARGETS="ruby20 ruby21" 0 KiB
[ebuild   R   *] www-client/surf-0.6-r2::oiledmachine-overlay  USE="adblock gtk3 muslx32 savedconfig -gnu32 -gnu64" 0 KiB
[ebuild   R    ] dev-ruby/rdoc-4.2.0::gentoo  USE="-doc {-test}" RUBY_TARGETS="ruby20 ruby21 (-ruby22)" 0 KiB
[ebuild   R    ] dev-python/setuptools-18.4::gentoo  USE="{-test}" PYTHON_TARGETS="python2_7 python3_4 (-pypy) (-pypy3) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] dev-python/pyxattr-0.5.5::gentoo  USE="-doc {-test}" PYTHON_TARGETS="python2_7 python3_4 (-pypy) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] dev-python/certifi-2015.11.20::gentoo  PYTHON_TARGETS="python2_7 python3_4 (-pypy) (-pypy3) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] dev-python/m2crypto-0.22.3-r4::gentoo  PYTHON_TARGETS="python2_7" 0 KiB
[ebuild   R    ] dev-python/pygments-2.1.1::gentoo  USE="-doc {-test}" PYTHON_TARGETS="python2_7 python3_4 (-pypy) (-pypy3) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] sys-apps/portage-2.2.28-r99::x-portage  USE="(ipc) xattr -build -doc -epydoc (-selinux)" LINGUAS="-ru" PYTHON_TARGETS="python2_7 python3_4 (-pypy) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] net-wireless/crda-3.18-r1::gentoo  USE="-gcrypt (-libressl)" 0 KiB
[ebuild   R    ] dev-python/docutils-0.12::gentoo  PYTHON_TARGETS="python2_7 python3_4 (-pypy) (-pypy3) -python3_3 (-python3_5)" 0 KiB
[ebuild   R    ] virtual/package-manager-0::gentoo  0 KiB
[ebuild   R    ] media-video/mpv-0.9.2-r1::gentoo  USE="alsa cli -X -bluray -bs2b -cdio -doc-pdf -drm -dvb -dvd -egl -enca -encode -iconv -jack -jpeg -ladspa -lcms -libass -libav (-libcaca) -libguess -libmpv -lua -luajit -openal -opengl -oss -pulseaudio -pvr (-raspberry-pi) -rubberband -samba -sdl (-selinux) -v4l -vaapi (-vdpau) -vf-dlopen -wayland -xinerama -xscreensaver -xv" 0 KiB
[ebuild   R    ] net-wireless/wpa_supplicant-2.5-r1::gentoo  USE="dbus hs2-0 readline ssl -ap -eap-sim -fasteap -gnutls (-libressl) -p2p (-ps3) -qt4 -qt5 (-selinux) -smartcard -tdls -uncommon-eap-types (-wimax) -wps" 0 KiB
[ebuild   R    ] app-portage/layman-2.0.0-r3::gentoo  USE="git -bazaar -cvs -darcs -mercurial -subversion {-test}" PYTHON_TARGETS="python2_7 (-pypy)" 0 KiB
[ebuild   R    ] app-portage/gentoolkit-0.3.0.9-r2::gentoo  PYTHON_TARGETS="python2_7 python3_4 (-pypy) -python3_3" 0 KiB
[ebuild   R    ] media-sound/pulseaudio-8.0::x-portage  USE="X alsa alsa-plugin asyncns caps dbus gdbm glib gtk ipv6 ssl system-wide tcpd udev -bluetooth -doc -equalizer -gnome -jack (-libressl) -libsamplerate -lirc -native-headset (-neon) -ofono-headset (-orc) (-oss) -qt4 -realtime (-selinux) -sox (-systemd) {-test} (-webrtc-aec) (-xen) -zeroconf" 0 KiB
[ebuild   R    ] media-plugins/alsa-plugins-1.0.29::x-portage  USE="pulseaudio -debug -ffmpeg -jack -libsamplerate -speex" 0 KiB
[ebuild   R    ] media-sound/pavucontrol-3.0::gentoo  USE="nls" 0 KiB
[ebuild   R    ] www-client/firefox-45.2.0::x-portage  USE="bindist custom-cflags custom-optimization ffmpeg gmp-autoupdate gstreamer hwaccel jit pulseaudio system-harfbuzz system-icu system-jpeg (system-libevent) system-libvpx system-sqlite -dbus -debug -gstreamer-0 -gtk3 -hardened -jemalloc3 (-neon) (-pgo) (-selinux) -startup-notification (-system-cairo) {-test} -wifi" LINGUAS="-ach -af -an -ar -as -ast -az -be -bg -bn_BD -bn_IN -br -bs -ca -cs -cy -da -de -el -en_GB -en_ZA -eo -es_AR -es_CL -es_ES -es_MX -et -eu -fa -fi -fr -fy_NL -ga_IE -gd -gl -gu_IN -he -hi_IN -hr -hsb -hu -hy_AM -id -is -it -ja -kk -km -kn -ko -lt -lv -mai -mk -ml -mr -ms -nb_NO -nl -nn_NO -or -pa_IN -pl -pt_BR -pt_PT -rm -ro -ru -si -sk -sl -son -sq -sr -sv_SE -ta -te -th -tr -uk -uz -vi -xh -zh_CN -zh_TW" 0 KiB
[ebuild   R    ] dev-qt/qtgui-4.8.6-r4:4::x-portage  USE="accessibility exceptions glib mng qt3support tiff xv (-aqua) -cups -debug -egl -gtkstyle -nas -nis -pch -trace -xinerama" 0 KiB
[ebuild   R    ] dev-qt/qt3support-4.8.6-r99:4::musl  USE="accessibility exceptions (-aqua) -debug -pch" 0 KiB
[ebuild   R    ] app-admin/keepassx-2.0.2::x-portage  USE="{-test}" 0 KiB
[ebuild   R    ] x11-libs/xcb-util-0.4.0::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] x11-libs/xcb-util-image-0.4.0::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] x11-apps/xlsclients-1.1.3::gentoo  0 KiB
[ebuild   R    ] x11-apps/xbacklight-1.2.1-r1::gentoo  0 KiB
[ebuild   R    ] x11-libs/xcb-util-cursor-0.1.2::gentoo  USE="-doc -static-libs {-test}" 0 KiB
[ebuild   R    ] x11-base/xorg-x11-7.4-r2::gentoo  0 KiB
[ebuild   R    ] dev-perl/libwww-perl-6.150.0::gentoo  USE="ssl" 0 KiB
[ebuild   R    ] x11-misc/xscreensaver-5.34::gentoo  USE="jpeg opengl pam perl -gdm -new-login (-selinux) -suid -xinerama" 0 KiB
[ebuild   R    ] dev-perl/LWP-Protocol-https-6.60.0::gentoo  0 KiB
[ebuild   R    ] xfce-base/xfce4-session-4.12.1::gentoo  USE="nls xscreensaver -debug -policykit (-systemd) -upower" 0 KiB
[ebuild   R    ] xfce-base/xfce4-meta-4.12::gentoo  USE="svg -minimal" 0 KiB
[ebuild   R    ] sys-auth/polkit-0.113::musl  USE="introspection nls pam -examples -gtk -jit -kde (-selinux) (-systemd) {-test}" 0 KiB
[ebuild   R    ] sys-auth/consolekit-1.1.0::gentoo  USE="pam policykit -acl -cgroups -debug -doc -pm-utils (-selinux) {-test}" 0 KiB

Total: 663 packages (2 upgrades, 661 reinstalls), Size of downloads: 5818 KiB

 * IMPORTANT: 13 news items need reading for repository 'gentoo'.
 * Use eselect news read to view new items.
 
 ---
 package.use:
 www-client/chromium -tcmalloc custom-cflags
# required by www-client/chromium-51.0.2704.63::gentoo
# required by chromium (argument)
>=media-libs/harfbuzz-1.2.7 icu
# required by www-client/chromium-51.0.2704.63::gentoo
# required by chromium (argument)
>=sys-libs/zlib-1.2.8-r1 minizip
# required by www-client/chromium-51.0.2704.63::gentoo
# required by chromium (argument)
>=dev-libs/libxml2-2.9.4 icu
cross-x86_64-pc-linux-muslx32/binutils -selinux -multilib
cross-x86_64-pc-linux-muslx32/linux-headers -selinux -multilib
cross-x86_64-pc-linux-muslx32/musl -selinux -multilib
cross-x86_64-pc-linux-muslx32/gcc -selinux -boundschecking -d -gcj -gtk -libffi -mudflap -objc -objc++ -objc-gc -multilib
net-misc/curl curl_ssl_gnutls -curl_ssl_openssl
# required by media-libs/giblib-1.2.4::gentoo
# required by media-gfx/feh-2.9.3::gentoo
# required by feh (argument)
>=media-libs/imlib2-1.4.9 X
media-video/ffmpeg aac mp3 alsa gnutls -openssl
# required by x11-libs/wxGTK-3.0.2.0-r2::gentoo[X]
# required by net-ftp/filezilla-3.12.0.2::gentoo
# required by filezilla (argument)
>=x11-libs/pango-1.38.1 X
www-client/firefox gstreamer -jemalloc3 system-icu system-libvpx system-sqlite system-jpeg system-harfbuzz custom-cflags custom-optimization -hardened hwaccel -debug ffmpeg jit pulseaudio
# required by www-client/firefox-38.8.0::gentoo
# required by firefox (argument)
>=media-libs/libpng-1.6.21 apng
# required by www-client/firefox-38.8.0::gentoo
# required by firefox (argument)
>=dev-lang/python-2.7.10-r1:2.7 sqlite
# required by www-client/firefox-38.8.0::gentoo[system-libvpx]
# required by firefox (argument)
>=media-libs/libvpx-1.4.0 postproc
# required by www-client/firefox-38.8.0::gentoo[system-sqlite]
# required by firefox (argument)
>=dev-db/sqlite-3.12.0 secure-delete
# required by www-client/firefox-47.0.1::x-portage[system-sqlite]
# required by =firefox-47.0.1 (argument)
>=dev-db/sqlite-3.12.0 -debug
media-plugins/gst-plugins-meta alsa mp3 theora vorbis ogg aac opus ffmpeg http
# required by media-plugins/gst-plugins-meta-1.6.3::gentoo
# required by gst-plugins-meta (argument)
>=media-libs/gst-plugins-base-1.6.3 alsa
# required by media-plugins/gst-plugins-meta-1.6.3::gentoo
# required by gst-plugins-meta (argument)
>=media-libs/gst-plugins-base-1.6.3 theora
media-libs/flac -cpu_flags_x86_sse
cross-x86_64-pc-linux-muslx32/gcc -vtv -fortran -sanitize
sys-devel/gcc -vtv -fortran -sanitize
sys-devel/gdb nls server client -multitarget
x11-libs/gdk-pixbuf jpeg
sys-devel/gettext cxx
media-gfx/gimp exif jpeg png svg tiff
#dev-libs/gmp -cxx
www-plugins/gnash gtk sdl
sys-boot/grub grub_platforms_pc
x11-libs/gtk+:3 X wayland
#dev-scheme/guile threads
# required by dev-scheme/guile-2.0.0::gentoo
# required by guile (argument)
>=dev-libs/boehm-gc-7.4.2-r99 threads
media-gfx/imagemagick png jpeg X
media-libs/imlib2 gif jpeg png
net-misc/iputils -caps -filecaps
dev-qt/qtcore icu qt3support
dev-qt/qtgui qt3support mng tiff
# required by x11-libs/gtk+-2.24.30::gentoo
# required by app-editors/leafpad-0.8.18.1::gentoo
# required by leafpad (argument)
>=x11-libs/gdk-pixbuf-2.32.3 X
# required by x11-libs/gtk+-2.24.30::gentoo
# required by app-editors/leafpad-0.8.18.1::gentoo
# required by leafpad (argument)
>=x11-libs/cairo-1.14.6 X
media-libs/libvpx -cpu_flags_x86_sse3 -cpu_flags_x86_sse2 -cpu_flags_x86_sse -cpu_flags_x86_mmx
sys-devel/llvm -clang -gold
www-client/midori
# required by www-client/midori-0.5.11-r1::gentoo
# required by midori (argument)
>=app-crypt/gcr-3.18.0 gtk
media-sound/mpd -* alsa lame mpg123 curl network glib ffmpeg libmpdclient
#media-video/mplayer -* -X -xv -cdio -xscreensaver -osdmenu -dvd -dvdnav -truetype -enca -encode -libass -iconv -shm -unicode alsa network mp3 -faad cpu_flags_x86_3dnow cpu_flags_x86_3dnowext cpu_flags_x86_mmx cpu_flags_x86_mmxext cpu_flags_x86_sse cpu_flags_x86_sse2 cpu_flags_x86_sse3
media-video/mplayer -* -X -xv -cdio -xscreensaver -osdmenu -dvd -dvdnav -truetype -enca -encode -libass -iconv -shm -unicode alsa network mp3 -faad
media-video/mpv -dvd -enca -libass -opengl -xscreensaver -X -iconv
www-client/netsurf gtk -svgtiny
# required by media-libs/libsvgtiny-0.1.4::gentoo
# required by www-client/netsurf-3.5::gentoo[svg,svgtiny]
# required by netsurf (argument)
>=net-libs/libdom-0.3.0 xml
net-misc/networkmanager -* wifi ncurses dhcpcd gnutls
# required by sys-auth/consolekit-1.1.0::gentoo
# required by sys-auth/polkit-0.113::musl
# required by net-misc/networkmanager-1.0.12-r1::gentoo
# required by networkmanager (argument)
>=dev-libs/glib-2.46.2-r3 dbus
# required by sys-auth/polkit-0.113::musl
# required by net-misc/networkmanager-1.0.12-r1::gentoo
# required by networkmanager (argument)
>=sys-auth/consolekit-1.1.0 policykit
# required by net-misc/networkmanager-1.0.12-r1::gentoo[wifi]
# required by networkmanager (argument)
>=net-wireless/wpa_supplicant-2.5-r1 dbus
media-sound/pulseaudio dbus system-wide gtk
dev-cpp/gtkmm X wayland
dev-cpp/cairomm X
# required by dev-qt/qt3support-4.8.6-r99::musl
# required by dev-qt/qtgui-4.8.6-r4::gentoo[qt3support]
# required by dev-qt/qtcore-4.8.6-r99::musl[qt3support]
# required by qtcore:4 (argument)
>=dev-qt/qtsql-4.8.6-r1:4 qt3support
# required by dev-qt/qtwebkit-4.8.6-r1::gentoo[gstreamer]
# required by www-client/qupzilla-1.8.9::gentoo[qt4]
# required by qupzilla (argument)
>=dev-libs/libxml2-2.9.4 -icu
# required by dev-util/itstool-2.0.2::gentoo
# required by gnome-extra/zenity-3.18.1.1::gentoo
# required by media-sound/spotify-1.0.31::gentoo
# required by spotify (argument)
>=dev-libs/libxml2-2.9.4 python
#dev-util/strace unwind aio
www-client/surf gtk3 muslx32 adblock savedconfig
net-libs/webkit-gtk muslx32 -wayland
# required by net-libs/webkit-gtk-2.13.2::oiledmachine-overlay[opengl,webgl]
# required by www-client/surf-0.6-r1::oiledmachine-overlay[gtk3]
# required by www-client/surf::oiledmachine-overlay (argument)
>=x11-libs/cairo-1.14.6 opengl
media-libs/gst-plugins-bad opengl X
sys-apps/dbus X
net-libs/webkit-gtk -geoloc wayland -bmalloc nsplugin spell geoloc
# required by dev-libs/weston-1.9.0::gentoo[gles2]
# required by weston (argument)
>=media-libs/mesa-11.0.6 gles2 wayland
dev-libs/weston wayland-compositor xwayland jpeg webp
# required by dev-libs/weston-1.9.0::gentoo[xwayland]
# required by weston (argument)
>=x11-base/xorg-server-1.17.4 wayland
# required by dev-libs/weston-1.9.0::gentoo[xwayland]
# required by weston (argument)
>=x11-libs/cairo-1.14.6 xcb
app-emulation/wine abi_x86_32
dev-util/pkgconfig internal-glib
sys-apps/help2man -nls
x11-base/xorg-server glamor
x11-drivers/xf86-video-nouveau glamor
x11-misc/xscreensaver opengl jpeg
# required by www-client/chromium-52.0.2743.82::gentoo
# required by chromium (argument)
>=dev-libs/libxml2-2.9.4 icu
# required by media-sound/pulseaudio-8.0::gentoo[alsa-plugin,alsa]
# required by www-client/firefox-45.2.0::x-portage[pulseaudio]
# required by @selected
# required by @world (argument)
>=media-plugins/alsa-plugins-1.0.29 pulseaudio

----

package.mask:
>=cross-x86_64-pc-linux-muslx32/gcc-9999
=net-misc/curl-7.49.0
app-text/enchant::oiledmachine-overlay
>cross-x86_64-pc-linux-muslx32/gcc-4.9.3
>sys-devel/gcc-4.9.3
#=dev-vcs/git-2.7.3-r1
dev-libs/glib::x-portage
dev-libs/glib::gentoo
#=dev-libs/gmp-6.0.0a
#=dev-scheme/guile-2.0.11
dev-scheme/guile::gentoo
<sys-devel/libtool-2.4.3-r2
>sys-devel/llvm-3.5.0-r99
www-client/midori::gentoo
*/*::musl-extras
>sys-libs/ncurses-5.9-r5
<sys-apps/openrc-0.13.0
<sys-process/procps-3.3.9-r2
<dev-lang/perl-5.18.0
sys-process/psmisc::musl
app-accessibility/speech-dispatcher::oiledmachine-overlay
#www-client/surf::oiledmachine-overlay
net-libs/webkit-gtk::oiledmachine-overlay
#=net-libs/webkit-gtk::x-portage
net-libs/webkit-gtk::musl
net-libs/webkit-gtk::gentoo
#>net-libs/webkit-gtk-2.0.4
app-arch/xz-utils::gentoo

----
#contents of /etc/portage/make.conf.cross
CHOST=x86_64-pc-linux-muslx32
CBUILD=x86_64-pc-linux-gnux32
ARCH=amd64

HOSTCC=x86_64-pc-linux-gnux32-gcc

ROOT=/usr/${CHOST}/

#ACCEPT_KEYWORDS="amd64 ~amd64"
ACCEPT_KEYWORDS="amd64"

USE="${USE} -pam"
USE="${USE} -hardened -pax_kernel"

CFLAGS="-O2 -pipe"
CXXFLAGS="${CFLAGS}"

#FEATURES="-collision-protect sandbox buildpkg noman noinfo nodoc nostrip splitdebug"
FEATURES="-collision-protect sandbox buildpkg"
# Be sure we dont overwrite pkgs from another repo..
PKGDIR=${ROOT}packages/
PORTAGE_TMPDIR=${ROOT}tmp/

#ELIBC="__LIBC__"
ELIBC="musl"

PKG_CONFIG_PATH="${ROOT}usr/lib/pkgconfig/"
#PORTDIR_OVERLAY="/usr/portage/local/"

PORTDIR_OVERLAY="${PORTDIR_OVERLAY} ${ROOT}var/lib/layman/musl"
#PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/local/portage"
PORTDIR_OVERLAY="${PORTDIR_OVERLAY} ${ROOT}usr/local/portage"
ALSA_CARDS="emu10k1"
VIDEO_CARDS="nouveau radeon"

MAKEOPTS="-j1"

-----
#contents of /etc/portage/make.conf.native
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
CFLAGS="-O2 -pipe"
#CFLAGS="-march=native -O2 -pipe"
#CFLAGS="-O2 -pipe -fomit-frame-pointer"
#CFLAGS="-O2 -pipe"
#CFLAGS="-O0 -pipe -ggdb -g" #debug
CXXFLAGS="${CFLAGS}"
# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-muslx32"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="bindist mmx sse sse2"
#USE="${USE} -pam"
USE="${USE} -hardened -pax_kernel"
#USE="${USE} -introspection"

#FEATURES="ccache -collision-protect sandbox buildpkg noman noinfo nodoc nostrip splitdebug"
#FEATURES="ccache sandbox buildpkg nostrip"
FEATURES="ccache sandbox buildpkg"
#FEATURES="ccache sandbox nostrip splitdebug"

ACCEPT_KEYWORDS="amd64"

PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
#PKGDIR="/packages"


PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /var/lib/layman/musl"
#PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/local/musl-extras"
PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/local/oiledmachine-overlay"
PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/local/portage"

ALSA_CARDS="emu10k1"
VIDEO_CARDS="nouveau radeon r600"
CPU_FLAGS_X86="3dnow 3dnowext mmx mmxext sse sse2 sse3"
COLLISION_IGNORE="${COLLISION_IGNORE} /usr/share/locale/locale.alias"
I_KNOW_WHAT_I_AM_DOING="yes"

PORTAGE_IONICE_COMMAND="ionice -c 3 -p \${PID}"
#PORTAGE_NICENESS="15"

MAKEOPTS="-j1"

