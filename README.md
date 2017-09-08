# muslx32
This is an unofficial muslx32 (musl libc and x32 ABI) overlay for Gentoo Linux

### About the muslx32 profile

This profile uses a 64-bit linux kernel with x32 abi compatibility.  All of the userland libraries and programs are built as native x32 ABI without duplicate 64-bit and 32-bit versions (a.k.a. multilib).  The profile contains patches that fix x32 problems and musl problems.  Other overlays seperate them, but in this overlay we combine them.

### Current goals

The current goal is trying to get popular packages and necessary developer tools working on the platform/profile for widespread adoption.

### Why musl and x32 and Gentoo? 

Musl because it is lightweight.  x32 ABI because it reduces memory usage.  Alpine Linux, an embedded mini distro, had Firefox tagging my USB for many tabs resulting in a big slow down.  I was really disappointed about Alpine and the shortcomings of the other previously tested distros.  It was many times slower than the RAM based distros such as Linux Mint and Slax, so there was a motivation to work on muslx32 for Gentoo.  Tiny Linux and Slax packages were pretty much outdated.  blueness said that he wouldn't make muslx32 as top priority or it wasn't his job to do or after the hardened gcc patches for the platform were ready, so I decided to just do it myself without the hardened part.

### What is x32?

x32 ABI is 32-bit (4-bytes) per integer, long, pointer using all of the x86_64 general purpose registers identified as (rax,rbx,rcx,r11-r15,rsi,rdi) and using sse registers.  Long-long integers are 8 bytes.  C/C++ programs will use __ILP32__ preprocessor checks to distinguish between 32/64 bit systems.  The build system may also compare sizeof(void*) to see if it has 4 bytes for 32-bit for 8 bytes and 64-bit for LP64 (longs are 8 bytes as well as pointers) and __x86_64__ defined.  

### Advantages of this platform

#### x32 ABI vs x86 ABI
x32 is better than x86 because the compiler can utilize the x86_64 calling convention by dumping arguments to the registers first before dumping additional arguments on the stack.  The compiler can futher optimize the code by reducing the number of instructions executed and utilize the full register and 64 bit instructions.

#### x32 ABI vs x86_64 ABI
x32 is better than x86_64 because of reduced pointer size and reduced virtual space.  Reduced virtual space is better safeguard against memory hogs and better memory/cache locality to reduce cache/page miss in theory.

### Disadvantages of the unilib muslx32 platform

No binary exclusive packages work (e.g. adobe flash, spotify, genymotion, virtualbox, etc.) since no major distro currently completely supports it so no incentive to offer a x32 ABI version.  Some SIMD assembly optimizations are not enabled.  Some assembly based packages don't work because they need to be hand edited.  It is not multilib meaning that there may be problems with packages that only offer x86 or x86_64 like wine [which has no x32 support].

For Adobe Flash try using Shumway Firefox addon.  It may or not work for some content.

### Who should use muslx32?

Early adopters of 64 bit and older PCs and laptops

Those that enjoy the challenge of fixing bugs especially assembly bugs and those related to musl.

### Who should not use muslx32?

Whenver there is high risk involved.  Some situations like online test taking require Adobe Flash to work.  Online banking and commerce or online shopping, you should not use this because the browser Firefox is outdated and hard to fix.

### Other recommendations

Use -Os and use kernel z3fold to significantly reduce swapping.  Use cache to ram for Firefox if using Gentoo from a usbstick.

### Sources and credits of patches

Some patches for musl libc and x32 came from Alpine Linux (Natanael Copa), Void Linux, debian x32 port (Adam Borowski), musl overlay (Anthony G. Basile/blueness), musl-extras (Aric Belsito/lluixhi)) .... (will update this list)

### What you can do to help?

* Clean the ebuilds with proper x32 ABI and musl CHOST checks and submit them to Gentoo.
* Write/Fix assembly code for the jit based packages and assembly based packages.
* Test and patch new ebuilds for these use cases or stakeholders: server, web, gaming, etc, entertainment, developer, science, business, graphic artists.
* Fix the build system to get rid of the bashrc script and odd quirks.
* Check and fix packages that use elf_x86_64 when it should link using elf32_x86_64.
* Check and fix packages that use constant numbers for syscalls.  The syscall needs to added/or'ed by __X32_SYSCALL_BIT or 0x40000000.
* Check all sizeof(void*) and similar to be sure they are in the 4G address range if porting from 64 bit code.
* Replace all important longs that assume 64-bit as long long.  In x32, long is actual 4 bytes.
* Check and fix the build system scripts--inspect both the linker flags and the compiler flags and constants--if it did not provide a special case for x32 ABI.

### Where can we meet on IRC?

#gentoo-muslx32 on freenode

### Working packages

Here are some major packages listed that may be difficult to port but happen to work.

package | notes
--- | ---
firefox 45.x only | It works except when using pulseaudio and jit.  Javascript works but through the slower interpreter path. YouTube works with alsa audio.  Firefox 47+ and 49+ is broken on x32 with 45.x patches applied.  It is an outdated version an may pose a security risk.  Use a different computer or live cd or partition with amd64 x86 and firefox updated continously.
strace | It depends on musl from this overlay since bits/user.h is broken in musl.
gdb | It depends on musl from this overlay since bits/user.h is broken in musl.
X | You need to copy configs/20-video.conf from muslx32toolkit to etc/X11/xorg.conf.d/20-video.conf and edit it especially the Hz and the driver.  This special file loads the proper modules explicitly in the correct order instead of lazy loading them.  DRI3 set to 1 breaks opengl so you may need to set it to 0.
wpa_supplicant | Works as expected.  Untested GUI if any.
xf86-video-nouveau | Works on Geforce2 MX
xf86-video-ati | Works if it doesn't pull proprietary drivers such as opencl (AMDAPP) or AMDGPU(-PRO) drivers.
mplayer | Works when streaming radio
mpd | Should work from past experience
geany | Works showing IDE.
dwm and dmenu | Works as expected.  Moving windows to other virtual desktops.  Dmenu loads menu immediate but not functioning at one instance after hours of use and cannot be loaded without killing X.
xfce4 | Does show desktop.  May possibly not log off first time but it fixes itself.
aterm | Works only from this overlay.
xfce4-terminal | Works as expected.
gimp | Can draw with basic shapes.
xscreensaver | Opengl screen savers tested working.
mesa-progs | Glxgears works on working opengl.
chrony and ntpd | Chrony needs musl struct timex patched with musl from this overlay.  don't forget to grab the timezone-data package and set /etc/timezone.
alsa | You may need to copy _.asound.rc to `/<user>/.asound.rc` to get sound working for Firefox.  It works without .asound.rc with mplayer.
gnu screen | Allows to copy and paste and have multiple apps run in each virtual terminal
links | Works when downloading and viewing pages
lxde-meta | Works on load and with menu lanucher
evince | Works showing pdf
inkscape | Works when drawing basic shapes.
wireshark | Works when displaying when opening pcap.  Untested for capturing. 
audacious | Works when playing mp3
pidgin | Works with aim
GPicView | Showed picture without segfault.
gucharmap | Works showing characters
PCManFM | Works viewing directory.
vlc | Works when playing video
keepassx | Works but needs qtcore and qtgui patch applied to properly display folders.
leafpad | Works on save and load file
emacs | May be slow loading but it should work.  Tested under chroot but not native.
vi | It should work.  Tested under chroot but not native.
blender | Works on quick run.  Not fully tested.
audacity | Shows interface and plays sound
ncftp | Works when connecting to public ftp server and downloading file
thunar | Works when traversing folders
xarchiver | Works when decompressing zip files
apache | Works on localhost
php | Shows phpinfo for apache.  php-fpm segfaults with nginx and doesn't show phpinfo()
phpmyadmin | Shows database tables and rows
mariadb | Tested with phpmyadmin
nginx | Shows "it works!"
gentoo-sources or any linux kernel | It may require you to manually patch it to use the BFD linker.  See https://github.com/orsonteodoro/muslx32/issues/3 .

### Buggy

The following are may present bugs after trying to fix assembly optimizations.  Disabling use flags (mmx,sse,sse2) and some patches may fix the problem.  By default, these fixes are disabled.  You can test them by using the experimental use flag.  These packages work okay without problems with the experimental simd fixes disabled.

package | notes
--- | ---
libjpeg-turbo | will crash on some photos and may prevent pictures loading from the app that uses the library like for feh.
ffmpeg or firefox | It may not play some YouTube videos completely.  It will play a few seconds then stop.  It's either ffmpeg or Firefox's fault.  The debugger said ffmpeg from what I recall.

### Needs testing

The following major packages has been fixed and emerged but not tested.

package | notes
--- | ---
tor | anonymous network
privoxy | http proxy caching
rabbitvcs | git frontend like tortoise git
actkbd | configure custom hotkeys
cryptsetup | for managing dm-crypt/luks encrypted volumes
p7zip | 7zip compression
pm-utils | suspending or hibernating computer
ntfs3g | for connecting to windows partitions

### Broken packages

(Do not use the ebuild and associated patches from this overlay if broken if you are planning to fix it.  My personal patches may add more complications so do it from scratch again): 

package | notes
--- | ---
Makefile.in or make system | Use my bashrc script to fix it see the muslx32toolkit below.
Chromium | v8 javascript engine is broken for x32.  Intel V8 X32 team (Chih-Ping Chen, Dale Schouten, Haitao Feng, Peter Jensen and Weiliang Lin) were working on it in May 2013-Jun 2014, but it has been neglected and doesn't work since the testing of >=52.0.2743.116 of Chromium.  I can confirm that the older standalone v8 works from https://github.com/fenghaitao/v8/ on x32. I decided to stop working on this.  As of 20170507 there is some chance if someone other than me that will be able to get Chromium on x32.  The strategy to fix this is undo some changesets that cause the breakage and it has been working up to 5.4.200.  We need 5.4.500.31 which exactly matches chromium-54.0.2840.59 stable from the portage tree because the wrappers depend on a particular version of v8.  Progress can be found at https://github.com/orsonteodoro/muslx32/issues/2.  I stopped working on this because I cannot find the bug.  I had a working v8 but there are problems on the browser side not v8 JavaScript engine which did pass unit tests up to 5.3.201 and did have a working mksnapshot as of 5.4.259.  The browser interface does work, but it is not showing content from the web.
wayland | I don't know if it is just weston causing the problem
weston | Segfaults
pulseaudio | It cannot connect to pavucontrol or pulseaudio apps
webkit-gtk with suckless surf | It just gives a blank screen.  Jit is broken or something else related not relevant to the patches.  JavaScriptCore works for 2.0.4 on x32 works on standalone but it doesn't work when applied to 2.12.3.  2.0.4. is unstable and crashes out a lot.  Also, it seems that the LLint won't work alone until you enable the jit.  Yuqiang Xian of Intel was working on it but stopped in Apr 2013.
evdev | Semi broken and quirky; dev permissions need to be manually set or devices reloaded. init script fixes are in these instructions
grub2-install | It doesn't work natively in x32 use lilo.  you can still install grub from amd64 profile or partiton.
xterm | It works in root but not as user
mono | It is for C#.  The patches from PLD Linux are incomplete.  Details of the patch can be found on https://www.mail-archive.com/pld-cvs-commit@lists.pld-linux.org/msg361561.html for what needs to be done.  From my previous attempt, the fix is not trivial which PLD would suggest.
nodejs | V8 JavaScript engine, which it is based off of, doesn't support x32.
import (from imagematick) | It cannot take a screenshot use imlib2 instead.
wine | It's broken and never supported x32.  x86 (win32/win16) may never be supported but x86_64 based windows apps may be supported.  Problems and immaturity of musl may prevent it be ported to muslx32.  win32 uses x86 calling conventions which make it possibly impossible to support.  x32 uses x86_64 assembly instructions and same registers which makes it easier to port but porting may not go well and limit to programs compiled with the wine toolchain than those produced with the microsoft toolchain.
clang | Clang 3.7 does work with compiling a hello world program, but it still broken when used as system-wide compiler.  It failed with a simple program like gnome-calculator.  https://llvm.org/bugs/show_bug.cgi?id=13666 at comment 3 needs to be fixed first.  This ebuild will compile clang to the end even though the bug report says otherwise because we can skip over compiling atomic.c and gcc_personality_v0.c.
keepass | It requires mono.  Use keepassx instead but you may need to convert your key files first.
cinnamon and gnome-light | This is not supported because muslx32 uses edev and cinnamon or gnome-light requires systemd.  If you decide to emerge it, you will need to also edit those packages yourself to support any musl or x32 bugs.  Use xfce4-meta or lxde-meta as an alternative.
xmonad and ghc | There is no x32 abi ghc so it won't work unless we crosscompile/crossbuild it describe by https://gentoohaskell.wordpress.com/2017/04/15/ghc-as-a-cross-compiler-update/. 
libreoffice | Loads splash but crashes.
gparted | If you use hfs, there may be higher risk of data loss.  dependencies that rely on the hfs use flag and the gparted program need to be checked since patches to dependencies were manually applied.  sys-fs/diskdev_cmds is the package in question if you are worrying about which one I might have screwed up on manually patching. it shows some partitions on other drives but didn't show all paritions on 2TB drive and some other drives.
obs-studio | Segfaults on start.
cheese | It could not detect webcam.  Either the package or library or kernel driver is broken.  It shows limited gui.
networkmanager | It complains when trying to run daemon.
eog | Segfaults.  It could be library problem.  Use GPicView instead.
mirage | Segfaults.  It could be library problem. Use GPicView instead.
physlock | Runtime problem: physlock: /dev/null/utmp: Not a directory
weechat | Connecting to server problem.  Use hexchat instead.  It says: sending data to server: error 9 Bad file descriptor

### Notes

sys-kernel/genkernel contains subdir_mount use flag and custom patch only found in this overlay.  This will allow you to keep both the crossdev toolchain and the crossdev profile on the same partition and keep everything in-place.  Add subdir_mount=/usr/x86_64-pc-linux-muslx32 to your kernel parameters to your bootloader and both root= and real_root= point to your partition (e.g. /dev/sda15).  We keep the crossdev toolchain so we can compile ghc cross compiler and to fix musl just in case.  This also prevents any file transfer human mistakes from the old documentation, which ask you to move everything from the root into a trash folder (`/mnt/<foldername>/trash`) and pull everything from `/mnt/<foldername>/trash/usr/x86_64-pc-linux-muslx32` into the root of the partition /mnt/<foldername>.

### Instructions for creating the muslx32 toolchain

You need the muslx32toolkit below.  It has convenience scripts to build stage3 and stage4 images.  You can build the images using your existing Gentoo installation.  It can fully automate building from crossdev toolchain, to stage 3 image, to stage 4 image, and finally to stage 4 extras.

Building the stage 3/4 image will take around 2 days [1 day up to stage4, 1 day for stage 4 extras (x11,firefox,etc)] with the muslx32toolkit which has been cut from the old documented method which took weeks.  You can still follow the old method by just reading the scripts and preforming the steps by hand to understand how to build an image using a cross compiler and cross toolchain infrastructure (i.e. `<crossdev-profile-triplet>-emerge -e system`) for those more interested in how crossdev works.

https://github.com/orsonteodoro/muslx32toolkit
