# Script for CI system build
#
# Alexander Smirnov <asmirnov@ilbers.de>
# Copyright (c) 2016-2018 ilbers GmbH

#!/bin/sh

ES_BUG=3

# Export $PATH to use 'parted' tool
export PATH=$PATH:/sbin

# Go to Isar root
cd $(dirname $0)/..

# Start build in Isar tree by default
BUILD_DIR=./build

BB_ARGS="-v"

show_help() {
    echo "This script builds the default Isar images."
    echo
    echo "Usage:"
    echo "    $0 [params]"
    echo
    echo "Parameters:"
    echo "    -b, --build BUILD_DIR set path to build directory. If not set,"
    echo "                          the build will be started in current path."
    echo "    -c, --cross           enable cross-compilation."
    echo "    -d, --debug           enable debug bitbake output."
    echo "    -f, --fast            build reduced set of configurations."
    echo "    -q, --quiet           suppress verbose bitbake output."
    echo "    --help                display this message and exit."
    echo
    echo "Exit status:"
    echo " 0  if OK,"
    echo " 3  if invalid parameters are passed."
}

# Parse command line to get user configuration
while [ $# -gt 0 ]
do
    key="$1"

    case $key in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--build)
        BUILD_DIR="$2"
        shift
        ;;
    -c|--cross)
        CROSS_BUILD="1"
        ;;
    -d|--debug)
        BB_ARGS="$BB_ARGS -d"
        ;;
    -f|--fast)
        FAST_BUILD="1"
        ;;
    -q|--quiet)
        BB_ARGS=""
        ;;
    *)
        echo "error: invalid parameter '$key', please try '--help' to get list of supported parameters"
        exit $ES_BUG
        ;;
    esac

    shift
done

# Setup build folder for the current build
if [ ! -d $BUILD_DIR ]; then
        mkdir -p $BUILD_DIR
fi
source isar-init-build-env $BUILD_DIR

if [ -n "$CROSS_BUILD" ]; then
    sed -i -e 's/ISAR_CROSS_COMPILE ?= "0"/ISAR_CROSS_COMPILE ?= "1"/g' conf/local.conf
fi

if [ -n "$FAST_BUILD" ]; then
    # Start build for the reduced set of configurations
    # Enforce cross-compilation to speed up the build
    # Enable use of cached base repository
    sed -i -e 's/ISAR_CROSS_COMPILE ?= "0"/ISAR_CROSS_COMPILE ?= "1"/g' conf/local.conf
    bitbake $BB_ARGS -c cache_base_repo \
        multiconfig:qemuarm-stretch:isar-image-base \
        multiconfig:qemuarm64-stretch:isar-image-base \
        multiconfig:qemuamd64-stretch:isar-image-base
    while [ -e bitbake.sock ]; do sleep 1; done
    sudo rm -rf tmp
    sed -i -e 's/#ISAR_USE_CACHED_BASE_REPO ?= "1"/ISAR_USE_CACHED_BASE_REPO ?= "1"/g' conf/local.conf
    bitbake $BB_ARGS \
        multiconfig:qemuarm-stretch:isar-image-base \
        multiconfig:qemuarm64-stretch:isar-image-base \
        multiconfig:qemuamd64-stretch:isar-image-base
else
    # Start build for all possible configurations
    bitbake $BB_ARGS \
        multiconfig:qemuarm-jessie:isar-image-base \
        multiconfig:qemuarm-stretch:isar-image-base \
        multiconfig:qemuarm-buster:isar-image-base \
        multiconfig:qemuarm64-stretch:isar-image-base \
        multiconfig:qemui386-jessie:isar-image-base \
        multiconfig:qemui386-stretch:isar-image-base \
        multiconfig:qemui386-buster:isar-image-base \
        multiconfig:qemuamd64-jessie:isar-image-base \
        multiconfig:qemuamd64-stretch:isar-image-base \
        multiconfig:qemuamd64-buster:isar-image-base \
        multiconfig:rpi-jessie:isar-image-base
    # qemu-user-static of <= buster too old to build that
    #multiconfig:qemuarm64-buster:isar-image-base
fi

cp -a ${ISARROOT}/meta/classes/dpkg-base.bbclass ${ISARROOT}/meta/classes/dpkg-base.bbclass.ci-backup
echo -e "do_fetch_append() {\n\n}" >> ${ISARROOT}/meta/classes/dpkg-base.bbclass

bitbake $BB_ARGS multiconfig:qemuamd64-stretch:isar-image-base

mv ${ISARROOT}/meta/classes/dpkg-base.bbclass.ci-backup ${ISARROOT}/meta/classes/dpkg-base.bbclass
