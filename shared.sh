#!/bin/sh
# Shared definitions for buildroot scripts

# The defconfig from the buildroot directory we use for BBB builds
BBB_DEFCONFIG=configs/beaglebone_defconfig
# The place we store customizations to the BBB configuration
MODIFIED_BBB_DEFCONFIG=base_external/configs/aesd_bbb_defconfig
# The defconfig from the buildroot directory we use for the project
AESD_DEFAULT_DEFCONFIG=${BBB_DEFCONFIG}
AESD_MODIFIED_DEFCONFIG=${MODIFIED_BBB_DEFCONFIG}
AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT=../${AESD_MODIFIED_DEFCONFIG}
