#!/bin/bash
USE_AUR=1
DN_TOP=$(pwd)
DN_ROOT="${DN_TOP}/archroot"

# since the apt-get place lock in $ROOTFS/var/cache/apt/archives
# we need to seperate the dir from multiple instances if we want to share the apt cache
# so we place *.deb and lock file into two folders in ${SRCDEST}/apt-cache-armhf and ${srcdir}/apt-cache-armhf seperately

# link the *.xz from ${SRCDEST}/pacman-pkg-armhf to ${srcdir}/pacman-pkg-armhf
pkgcache_link2srcdst() {
    # the read-only dir stores the real files
    PARAM_DN_STORE=$1
    shift
    # the relative path name for the real files
    PARAM_DN_BASE=$1
    shift
    # the dir contains the symbol links
    PARAM_DN_LINK=$1
    shift

    sudo mkdir -p "${PARAM_DN_STORE}"
    sudo mkdir -p "${PARAM_DN_LINK}"
    sudo mkdir -p "${PARAM_DN_LINK}-real"
    sudo mount -o bind "${PARAM_DN_STORE}" "${PARAM_DN_LINK}-real"
    cd "${PARAM_DN_LINK}"
    find "${PARAM_DN_BASE}" -name "*.xz" -type f | while read i; do
        FN="$(basename ${i})"
        sudo rm -f "${FN}"
        sudo ln -s "${i}" "${FN}"
    done
    cd -
}

# backup the new downloaded *.xz from ${srcdir}/apt-cache-armhf to ${SRCDEST}/apt-cache-armhf
pkgcache_backup2srcdst() {
    # the read-only dir stores the real files
    PARAM_DN_STORE=$1
    shift
    # the relative path name for the real files
    PARAM_DN_BASE=$1
    shift
    # the dir contains the symbol links
    PARAM_DN_LINK=$1
    shift

    # make sure the files are not symbol links
    cd "${PARAM_DN_LINK}"
    find "${PARAM_DN_LINK}" -name "*.xz" -type f | while read i; do
        FN="$(basename ${i})"
        sudo mv "${i}" "${PARAM_DN_BASE}"
        sudo rm -f "${FN}"
        sudo ln -s "${PARAM_DN_BASE}/${FN}" "${FN}"
    done
    sudo umount "${PARAM_DN_LINK}-real"
    sudo rmdir  "${PARAM_DN_LINK}-real"
    find "${PARAM_DN_LINK}" | while read i ; do sudo rm -rf $i; done
    cd -
}

cat > Dockerfile << EOF
# Arch Linux baseline docker container
# Generated on `date`
# Read the following to learn how the root filesystem image was generated:
# https://github.com/yhfudev/docker-archlinux/blob/master/README.md
FROM scratch
MAINTAINER yhfudev <yhfudev@gmail.com>
ADD archlinux.tar.xz /
RUN pacman -Syyu --needed --noconfirm

# install, run and remove reflector all in one line to prevent extra layer size
RUN pacman -S --needed --noconfirm reflector; reflector --verbose -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist; pacman -Rs --noconfirm reflector

EOF

# if supports AUR
if [ "${USE_AUR}" = "1" ]; then
    cat >> Dockerfile << EOF
# install development packages
RUN pacman -S --noconfirm --needed base-devel

# no sudo password for users in wheel group
RUN sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers

# create docker user
RUN useradd -m -G wheel docker

WORKDIR /home/docker
# install yaourt
RUN su -c "(bash <(curl aur.sh) -si --noconfirm package-query yaourt)" -s /bin/bash docker

USER docker
# clean up
RUN sudo rm -rf /home/docker/*

# install packer and update databases
RUN yaourt -Syyua --noconfirm --needed packer
USER root

EOF
fi

if [ ! -f "archlinux.tar.xz" ]; then
    curl https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-arch.sh > ./mkimage-arch.sh
    chmod +x mkimage-arch.sh

    sed -i.bak \
        -e 's/| docker import - archlinux/-af archlinux.tar.xz/g' \
        -e '/docker run --rm -t archlinux echo Success./d' \
        mkimage-arch.sh

    curl https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-arch-pacman.conf > mkimage-arch-pacman.conf

echo "Building Arch Linux-docker root filesystem archive."
TMPDIR=${DN_ROOT} sudo ./mkimage-arch.sh
echo "Arch Linux-docker root filesystem archive build complete."

    rm -f mkimage-arch.sh
    rm -f mkimage-arch.sh.bak
    rm -f mkimage-arch-pacman.conf
fi
