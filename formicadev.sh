#!/bin/sh

# formicadev.sh v0.1.1
# Setup a development environment for the formica firmware.
# Currently uses mspgcc4 and msp430-gdbproxy.
# If you have git, a C compiler and the required libraries it will also try to
# build fetproxy, which is a GPL alternative to msp430-gdbproxy.

# BEERWARE LICENSE
# Copyright (C) 2009 Bernd Stolle <bsx+formica@0xcafec0.de>
# As long as you retain this notice you can do whatever you want with this.
# If you like it you can buy me a beer in return.

MSPGCC_URL="http://sourceforge.net/projects/mspgcc4/files/GCC-4.4.2-GDB-7.0-20091124/20091124-msp430-gcc-4.4.2-gdb-7.0-insight-6.8.7z/download"
GDBPROXY_BIN_URL="http://sourceforge.net/projects/mspgcc/files/msp430-gdbproxy/2006-11-14/msp430-gdbproxy/download"
LIBHIL_URL="http://sourceforge.net/projects/mspgcc/files/msp430-gdbproxy/2006-11-14/libHIL.so/download"
LIBMSP430_URL="http://sourceforge.net/projects/mspgcc/files/msp430-gdbproxy/2006-11-14/libMSP430.so/download"

FETPROXY_REPO="git://gitorious.org/fetproxy/mainline.git"
ORIG_FIRMWARE_REPO="https://lilafisch@github.com/lilafisch/formica_muc3.git"

GIT=`which git`
WGET=`which wget`
UN7Z=`which 7z`

setupTools() {
    echo "setting up mspgcc4 and msp430-gdproxy"
    mkdir -p $TARGET_PATH
    cd $TARGET_PATH
    $WGET $MSPGCC_URL -O dl-msp430-gcc-6.8.7z
    $UN7Z x *-msp430-gcc-*.7z
    mkdir -p $TARGET_PATH/downloads
    mv *-msp430-gcc-*.7z $TARGET_PATH/downloads
    mv *msp430-gcc* tools
    cd $TARGET_PATH/tools/bin
    $WGET $GDBPROXY_BIN_URL -O msp430-gdbproxy
    chmod +x msp430-gdbproxy
    cd $TARGET_PATH/tools/lib
    $WGET $LIBHIL_URL -O libHIL.so
    $WGET $LIBMSP430_URL -O libMSP430.so
    cd $TARGET_PATH/tools/bin
    cat >setenv.sh <<SETENV
# you must source this file in your current shell

FORMICA_TOOLS=$TARGET_PATH/tools
export FORMICA_TOOLS
PATH=\$FORMICA_TOOLS/bin:\$PATH
export PATH
LD_LIBRARY_PATH=\$FORMICA_TOOLS/lib:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

SETENV
echo "tool setup done, run 'source $TARGET_PATH/tools/bin/setenv.sh' in your current shell to activate the development environment"
}

setupFETProxy() {
    if [ -z `which cc` ]; then
        echo "no compiler found, not building fetproxy"
        exit 2
    fi
    pkg-config --exists glib-2.0
    if [ $? -ne 0 ]; then
        echo "glib is missing on your system, not builging fetproxy";
        exit 3
    fi
    pkg-config --exists gobject-2.0
    if [ $? -ne 0 ]; then
        echo "gobject is missing on your system, not building fetproxy";
        exit 3
    fi
    pkg-config --exists gnet-2.0
    if [ $? -ne 0 ]; then
        echo "gnet is missing on your system, not building fetproxy";
        exit 3
    fi
    if [ ! -f /usr/lib/libelf.so ]; then
        echo "libelf is missing on your system, not building fetproxy";
        exit 3
    fi
    echo "trying to build fetproxy"
    cd $TARGET_PATH/src
    $GIT clone $FETPROXY_REPO fetproxy
    cd fetproxy
    make
    cp fetproxy $TARGET_PATH/tools/bin
    echo "built and installed fetproxy"
}

setupSources() {
    echo "checking out original firmware sources"
    mkdir -p $TARGET_PATH/src
    cd $TARGET_PATH/src
    $GIT clone $ORIG_FIRMWARE_REPO firmware
    echo "firmware checked out"
}

usage() {
    echo "usage: $0 TARGET_PATH"
}

TARGET_PATH=$1

if [ -z $TARGET_PATH ]; then
    usage
    exit 1
fi

if [ -z $WGET ]; then
    echo "you need to install wget before proceeding"
    exit 2;
fi

if [ -z $UN7Z ]; then
    echo "7zip command line tools are required to extract mspgcc4"
    exit 2;
fi

echo "will setup a formica development environment in $TARGET_PATH"

setupTools;

if [ -n $GIT ]; then
    setupSources
    setupFETProxy
else
    echo "git was not installed, will not setup fetproxy and firmware sources"
fi

echo "DONE"
