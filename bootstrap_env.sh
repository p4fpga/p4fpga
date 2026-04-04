#!/bin/bash

die () {
    if [ $# -gt 0 ]; then
        echo >&2 "$@"
    fi
    exit 1
}

function version_LT() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1";
}

SUDO=sudo
LDCONFIG=ldconfig

install_linux_packages() {
    ubuntu_release=$(lsb_release -r | cut -f 2)

    apt_packages="g++ git automake libtool bison flex libfl-dev \
		  libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev \
		  libboost-system-dev libboost-filesystem-dev \
		  pkg-config python3 python3-scapy tcpdump cmake \
		  libgc-dev"

    echo "Need sudo privs to install apt packages"
    $SUDO apt-get update || die "Failed to update apt"
    $SUDO apt-get install -y $apt_packages || die "Failed to install needed packages"
    
}


install_linux_packages
