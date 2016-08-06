# muslx32
muslx32 (musl libc and x32 abi) overlay for Gentoo Linux
You need use crossdev to build this.  Crossdev is used to build the cross-compile toolchain.  Use the cross-compile toolchain to build system.  Use the system to build world.

Expected Repositories and priorities:

gentoo
    location: /usr/portage
    sync-type: rsync
    sync-uri: rsync://rsync.gentoo.org/gentoo-portage
    priority: -1000

musl-extras (optional): https://github.com/lluixhi/musl-extras

musl
    location: /var/lib/layman/musl
    masters: gentoo
    priority: 0

x-portage
    location: /usr/local/portage <--- this repository
    masters: gentoo
    priority: 2

Works:
firefox - except audio and jit.  javascript works but through interpreter.
strace (for debugging)
gdb (for debugging)
X (for windowing system)
wpa_supplicant (for wifi)
xf86-video-nouveau

Broken: 
chromium (v8 javascript engine is broken for x32)
wayland (dunno)
weston (segfaults)
pulseaudio (cannot connect pavucontrol or pulseaudio apps)
webkit-gtk (just blank screen, jit is broken)

Masks:
>sys-libs/ncurses-5.9-r5

The following need to be cross-compiled and may interrupt emerge -e system.  
if your native compiles fail, build these as cross-compiled:
dev-libs/mpfr
sys-devel/gettext
sys-apps/which


Instructions to build stage 4 from stage 1 to 3 cross compile toolchain, system cross-compiled toolchain (x86_64-pc-muslx32-emerge -e system), system native toolchain (emerge -e system), to world (emerge -e world).  
Incomplete instructions.  Backup!  Adjust to your needs.


assuming sysrescuecd

setup wifi with nmtui

repartition the drive
100M boot as ext4
4G swap as linux swap
*G root ext4

mkfs.ext4 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

#important turn on swap before compiling
swapon /dev/sda2

get portage-latest from mirror
get current-stage3-x32 from mirror

unpack both

move portage into usr

cp /etc/resolv.conf /mnt/gentoo/etc
screen
chroot /mnt/gentoo /bin/bash

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

edit /etc/portage/make.conf
add line: source /var/lib/layman/make.conf

cd /usr/x86_64-pc-linux-muslx32/etc/portage
mv make.profile make.profile.orig
ln -s /usr/portage/profiles/hardened/linux/musl/amd64/x32 ./make.profile

cd /usr/x86_64-pc-linux-muslx32/etc/portage/package.use
nano gcc
cross-x86_64-pc-linux-muslx32/gcc -sanitize -fortran -vtv
sys-devel/gcc -sanitize -fortran -vtv

#build the cross compile toolchain
x86_64-pc-linux-muslx32-emerge -pve system

cp /usr/lib/libx32/
cp -a libx32/python2.7/site-packages lib/python2.7/site-packages
cp -a libx32/python3.4/site-packages lib/python3.4/site-packages

#emerge the 64 bit of lilo and use it
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

#the last confusing thing
#do this correctly or expect to do this all over
#you could create a snapshot of the system before proceeding.  restore if you mess up

cp /usr/x86_64-pc-linux-muslx32/etc/portage/make.conf /usr/x86_64-pc-linux-muslx32/etc/portage/make.conf.cross
cp /etc/portage/make.conf /usr/x86_64-pc-linux-muslx32/etc/portage/make.conf #copy the catalyst makefile
cd /usr/x86_64-pc-linux-muslx32/etc/portage
ln -s make.conf.cat make.conf

cd /usr/x86_64-pc-linux-muslx32
mkdir proc
mkdir dev

mount -t proc proc proc

#add missing dev
cd dev
mknod console c 0 0
mknod -m 666 null c 1 3
mknod -m 666 zero c 1 5

mount --bind /dev /usr/x86_64-pc-linux-muslx32/dev      #urandom fix

cp /usr/bin/python-wrapper /usr/x86_64-pc-linux-muslx32/usr/bin #temporary workaround
mkdir -p /usr/x86_64-pc-linux-muslx32/etc/env.d/python
cd /usr/x86_64-pc-linux-muslx32/etc/env.d/python/config
nano config
#add line:
python2.7

cd /usr/x86_64-pc-linux-muslx32
#copy the resolv.conf to ./etc
chroot ./ /bin/bash

#set the root password

#build the native toolchain
emerge -pve system

#remember to build mpfr, which, gettext as cross-compile if it fails then continue --resuming

#build the world
emerge -vuDN world

#remember to build mpfr, which, gettext as cross-compile if it fails then continue --resuming

#IMPORTANT
#remember to set your root password and users

add app-arch/gzip-1.7 to /usr/x86_64-pc-linux-muslx32/etc/package.accept_keywords

#add these musl x32 hacks to portage
#patch1: for buggy coreutils cp command permissions ownership bug
#patch2: for file editing directory bug
#patch3: for some unpacking exit code verification bug

#add to package.use/wpa_supplicant
dev-util/pkgconfig internal-glib
sys-apps/help2man -nls

add to /etc/portage/make.conf
FEATURES="${FEATURES} nostrip splitdebug"

emerge wpa_supplicant #for wifi

#recommended for wifi
emerge wpa_supplicant
emerge dhcpcd
emerge chrony
emerge wireless-tools
emerge nano

#optional
emerge screen
emerge links

#tricky part
#you can bork your system if you get it wrong and need to start from scratch again

#last step put old files into trash and move the cross compiled stuff in root
#should snapshot or backup the system to be safe and restore/undo it if it fails
mkdir trash
mv * trash
mv trash/usr/x86_64-pc-linux-muslx32/* ./

reboot

#alsa-sound needs permissions corrected
#to fix add the following /etc/init.d/fixalsa
#do a     find /sys/devices -name "pcm*"         to find them all

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
        udevadm test /sys/devices/pci0000:00/0000:00:11.5/sound/card0/controlC0 2&>1 >/dev/null
        udevadm test /sys/devices/pci0000:00/0000:00:11.5/sound/card0/pcmC0D0c 2&>1 >/dev/null
        udevadm test /sys/devices/pci0000:00/0000:00:11.5/sound/card0/pcmC0D0p 2&>1 >/dev/null
        udevadm test /sys/devices/pci0000:00/0000:00:11.5/sound/card0/pcmC0D1c 2&>1 >/dev/null
        udevadm test /sys/devices/pci0000:00/0000:00:11.5/sound/card0/pcmC0D1p 2&>1 >/dev/null
        return 0
}

#add fixalsa service
rc-update add fixalsa

#for xkeyboard-config
ln -s /usr/lib/gcc/x86_64-pc-linux-muslx32/4.9.3/libgomp.so.1 /lib/libgomp.so.1

#xorg.conf needs to be told explicity which modules to load.  It doesn't work the way it should like with glib under musl.
contents of /etc/X11/xorg.conf.d/20-nouveau.conf

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


