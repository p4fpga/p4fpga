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

    apt_packages="g++ git automake libtool libgc-dev bison flex libfl-dev \
		  libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev \
		  libboost-system-dev libboost-filesystem-dev \
		  pkg-config python python-scapy python-ipaddr tcpdump cmake"

    echo "Need sudo privs to install apt packages"
    $SUDO apt-get update || die "Failed to update apt"
    $SUDO apt-get install -y $apt_packages || die "Failed to install needed packages"
    
}


function install_protobuf() {
    tmpdir=$(mktemp -d)
    echo "Using $tmpdir for temporary build files"

    echo "Checking for and installing protobuf"
    if ! `pkg-config protobuf` || version_LT `pkg-config --modversion protobuf` "3.0.0"; then
	pushd $tmpdir
	git clone https://github.com/google/protobuf
	cd protobuf
	git checkout tags/v3.2.0
	git submodule update --init --recursive
	./autogen.sh && \
	    ./configure && \
	    make && \
	    $SUDO make install && \
	    $SUDO $LDCONFIG || \
		die "Failed to install protobuf"
	cd ../
	/bin/rm -rf protobuf
	PI_clean_before_rebuild=true
	popd # tmpdir
    fi

    rm -rf $tmpdir
}


install_linux_packages
install_protobuf
