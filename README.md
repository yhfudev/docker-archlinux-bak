# docker-archlinux
create a Arch Linux docker image

## Usage

Install dependencies
    sudo pacman -S git expect arch-install-scripts docker

Build baseline Arch Linux docker image
    git clone clone https://github.com/yhfudev/docker-archlinux.git
    cd docker-archlinux
    ./runme.sh
    MYUSER=${USER}
    MYARCH=$(uname -m)
    docker build -t ${MYUSER}/archlinux-${MYARCH}:latest .
