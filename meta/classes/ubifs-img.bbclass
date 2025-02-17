# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

python() {
    if not d.getVar("MKUBIFS_ARGS"):
        raise bb.parse.skiprecipe("mkubifs_args must be set")
}

UBIFS_IMAGE_FILE ?= "${IMAGE_FULLNAME}.ubifs.img"

IMAGER_INSTALL += "mtd-utils"

# Generate ubifs filesystem image
do_ubifs_image() {
    rm -f '${DEPLOY_DIR_IMAGE}/${UBIFS_IMAGE_FILE}'

    image_do_mounts

    # Create ubifs image using buildchroot tools
    sudo chroot ${BUILDCHROOT_DIR} /usr/sbin/mkfs.ubifs ${MKUBIFS_ARGS} \
                -r '${PP_ROOTFS}' '${PP_DEPLOY}/${UBIFS_IMAGE_FILE}'
}

addtask ubifs_image before do_image after do_image_tools
