#!/usr/bin/env bash

DN_TOP=$(pwd)
DN_ROOT="${DN_TOP}/archroot"
MYARCH=$(uname -m)

# https://raw.githubusercontent.com/l3iggs/docker-archlinux/master/buildme.sh
# https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-arch.sh

#Installation
mkdir -pv ${DN_ROOT}/var/lib/pacman
PKGIGNORELIST=(
    cryptsetup
    device-mapper
    dhcpcd
    iproute2
    jfsutils
#    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    openresolv
    pciutils
#    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    usbutils
#    vi
    xfsprogs
)
PKGIGNORE="${PKGIGNORELIST[*]}"
pacman --root ${DN_ROOT}/ -Sy base haveged --noconfirm
pacman --root ${DN_ROOT}/ -Rns ${PKGIGNORE}

#pacman --root ${DN_ROOT}/ -Syyu --needed --noconfirm
#pacman --root ${DN_ROOT}/ -S --needed --noconfirm reflector
#arch-chroot ${DN_ROOT} reflector --verbose -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist
#pacman --root ${DN_ROOT}/ -Rns --noconfirm reflector

chroot ${DN_ROOT} /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"
ln -s /usr/share/zoneinfo/UTC ${DN_ROOT}/etc/localtime
echo 'en_US.UTF-8 UTF-8' >> ${DN_ROOT}/etc/locale.gen
chroot ${DN_ROOT} locale-gen
cp /etc/pacman.d/mirrorlist ${DN_ROOT}/etc/pacman.d/mirrorlist

sed -i -e 's/^SigLevel.*/SigLevel = Never/g' ${DN_ROOT}/etc/pacman.conf

#Clean up
pacman -Rncs --root ${DN_ROOT}/ --noconfirm linux man-db man-pages

rm -rf ${DN_ROOT}/usr/share/locale
rm -rf ${DN_ROOT}/usr/share/man

# udev doesn't work in containers, rebuild /dev
DEV=${DN_ROOT}/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

#Archive
echo "compresssing archlinux ${MYARCH} ..."
tar --numeric-owner --xattrs --acls -C ${DN_ROOT} -c . -af archlinux-${MYARCH}-image.tar.xz

MYUSER=yhfu
docker import - ${MYUSER}/archlinux-${MYARCH}:latest < archlinux-${MYARCH}-image.tar.xz

# example:
# docker run -t -i ${MYUSER}/archlinux-${MYARCH}:latest bash