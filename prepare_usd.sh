#!/bin/sh
# Script to load the bootfiles and rootfs to uSD card (BeagleBoneBlack)
# Author: Sundar Krishnakumar
# Dependant packages: parted, mkfs
# Usage: sudo ./prepare_usd.sh -d /dev/sdX
# NOTE: 
# 1. This script is written for Buildroot environment and BeagleBoneBlack hardware
# 2. This script must be run from the root of your AESD respository.


MNT_DIR=/mnt

# Command line input validation
if [ $# -eq 2 ] && [ $1 = "-d" ]
then
    USD_DEVICE_PATH=$2
else
	echo "Usage: $0 [ -d ] <uSD device file absolute path>"
	exit 1
fi

# Check if the usd device fiel given by user is valid or not
USD_DEVICE=$(basename ${USD_DEVICE_PATH})
USD_DEVICE_INFO=$(lsblk | grep "${USD_DEVICE} ")

# if [ ! -b ${USD_DEVICE_PATH} ] 
if [ -z "${USD_DEVICE_INFO}" ] 
then
	echo "Invalid uSD block device file path: ${USD_DEVICE_PATH}"
	exit 1
else
	echo "uSD block device detected. Device path: ${USD_DEVICE_PATH}"
    
fi  

# Check if there is atleast one partition present the uSD device
USD_DEVICE_PART_TYPE=$(lsblk -r | grep "${USD_DEVICE}" | grep " part " | head -1 | cut -d\  -f6)

if [ "${USD_DEVICE_PART_TYPE}" != "part" ]
then
	echo "uSD device (${USD_DEVICE_PATH}) does not have the first partition"
	echo "Create it first using 'gparted' utility"
	exit 1
fi

# Warn that all data in uSD will be lost in this process
echo -n "You are going to lose your data in the uSD device. Continue? [y|n]: "

while true; do
	read inp

	if [ "${inp}" != "y" ] && [ "${inp}" != "n" ]
	then
		echo -n 'Incorrect input. Valid inputs - [y|N]:'
	else		
		break # Exit the loop	
	fi

done


if [ "${inp}" != "y" ]
then
	echo "User aborted the operation. Exiting.."
	exit 1
fi

# Unmount the uSD card partition by partition.
# Mounted partition are visible at /proc/self/mounts file

while true; do

	USD_DEVICE_PART=$(grep /dev/${USD_DEVICE} /proc/self/mounts | head -1 | cut -d\  -f1)

	if [ -z "${USD_DEVICE_PART}" ]
	then	

		break # Exit the loop	

	else

		echo "Unmounting the uSD device partition (${USD_DEVICE_PART})"

		# 2>&1 simply says redirect standard error to standard output.
		# ''> /dev/null 2>&1' If you don't want to produce any output, 
		# even in case of some error produced in the terminal.
		# Reference: https://stackoverflow.com/questions/10508843/what-is-dev-null-21		

		if (! umount ${USD_DEVICE_PART} > /dev/null 2>&1)
		then
			echo "Cannot unmount uSD device (${USD_DEVICE_PART})"
			exit 1
		fi		

	fi

done

# Create the BOOT and ROOTFS partitions
# partition1 size=256MB
# partition2 size=rest of the space

echo "Partitioning the uSD device (${USD_DEVICE_PATH})"
echo "Partition1 - BOOT (bootable)"
echo "Partition2 - ROOTFS"

DO_PARTITION=$(parted -s "${USD_DEVICE_PATH}" -- mklabel msdos \
    mkpart primary fat16 1MB 256MB 	\
    mkpart primary fat32 256MB 100% > /dev/null 2>&1)


if [ ${DO_PARTITION} ]
then

	echo "Cannot partition uSD device (${USD_DEVICE_PATH})"
	exit 1	

fi

# Set flags for each partition
# partition1 flags: boot,lba
# partition2 flags: None
DO_PARTITION_FLAGS=$(parted -s ${USD_DEVICE_PATH} set 1 boot on \
	set 2 lba off \
	> /dev/null 2>&1)

if [ ${DO_PARTITION_FLAGS} ]
then

	echo "Cannot set flags for partitions"
	exit 1	

fi

# NOTE: parted is not setting the partition type (fat16,ext4) for some unknown 
# reason, so using 'mkfs' utility to set partition type below

# Format partition1, set partition type (fat16) and partition label (BOOT)
FORMAT_PARTITION_2=$(mkfs.vfat -n BOOT "/dev/${USD_DEVICE}1" > /dev/null 2>&1)

if [ ${FORMAT_PARTITION_2} ]
then

	echo "Cannot set format partition1"
	exit 1	

fi

# Format partition2, set partition type (ext4) and partition label (ROOTFS)
FORMAT_PARTITION_2=$(mkfs.ext4 -n ROOTFS "/dev/${USD_DEVICE}2" > /dev/null 2>&1)

if [ ${FORMAT_PARTITION_2} ]
then

	echo "Cannot set format partition2"
	exit 1	

fi

# Create desctination directories in MNT_DIR and prepare for mount

mkdir -p ${MNT_DIR}/boot
mkdir -p ${MNT_DIR}/rootfs




# mount BOOT and ROOTFS partitions
echo "Mounting BOOT and ROOTFS partitions"

# Mount BOOT partition
if (! mount -t vfat "/dev/${USD_DEVICE}1" "${MNT_DIR}/boot" > /dev/null 2>&1)
then
	echo "Cannot mount partition (/dev/${USD_DEVICE}1)"
	exit 1
fi

# Mount ROOTFS partition
if (! mount -t ext4 "/dev/${USD_DEVICE}2" "${MNT_DIR}/rootfs" > /dev/null 2>&1)
then
	echo "Cannot mount partition (/dev/${USD_DEVICE}2)"
	exit 1
fi


# Copy contents into BOOT partition
cp ./buildroot/output/images/u-boot.img ${MNT_DIR}//boot
cp ./buildroot/output/images/zImage ${MNT_DIR}/boot
cp ./buildroot/output/images/MLO ${MNT_DIR}/boot
cp ./buildroot/output/images/uEnv.txt ${MNT_DIR}/boot
cp ./buildroot/output/images/am335x-boneblack.dtb ${MNT_DIR}/boot

# Copy contents into ROOTFS partition
tar -xvf ./buildroot/output/images/rootfs.tar -C ${MNT_DIR}/rootfs > /dev/null 2>&1

# Do sync. Very important!
sync

echo "uSD device prepared successfully!"