# Arch Linux baseline docker container
# Generated on Wed Dec 23 10:39:00 EST 2015
# Read the following to learn how the root filesystem image was generated:
# https://github.com/yhfudev/docker-archlinux/blob/master/README.md
FROM scratch
MAINTAINER yhfudev <yhfudev@gmail.com>
ADD ./archlinux-x86_64-20151222.tar.xz /
RUN pacman -Syyu --needed --noconfirm

# install, run and remove reflector all in one line to prevent extra layer size
RUN pacman -S --needed --noconfirm reflector; reflector --verbose -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist; pacman -Rs --noconfirm reflector

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

