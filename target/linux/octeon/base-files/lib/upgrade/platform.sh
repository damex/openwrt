#!/bin/sh

platform_copy_config() {
	local board="$(board_name)"
	local device

	case "${board}" in
		erlite)
			device="/dev/sda1"
			;;
		itus,shield-router)
			device="/dev/mmcblk1p1"
			;;
	esac

	# checks for:
	# 1. device variable is not empty
	# 2. device variable points to actual block device
	if [ ! -z "${device}" ] && [ -b "${device}" ] ; then
		mount -t "vfat" "${device}" "/mnt"
		cp -af "${UPGRADE_BACKUP}" "/mnt/${BACKUP_FILE}"
		umount "/mnt"
	fi
	return 0
}

platform_do_flash() {
	local sysupgrade_file="${1}"
	local kernel_file="${2}"
	local kernel_checksum_file="${kernel_file}.md5"
	local boot_device="${3}"
	local root_device="${4}"
	# find a sysupgrade directory by looking inside sysupgrade file
	local sysupgrade_directory="$(tar tf ${sysupgrade_file} | awk -F '/' '/^sysupgrade/ {print $1; exit}')"
	# checks if sysupgrade directory variable is empty and exits with code 1
	[ -z "${sysupgrade_directory}" ] && return 1

	# checks for:
	# 1. sysupgrade file does not exist
	# 2. boot device is not a block device
	# 3. root device is not a block device
	# and exits with code 1
	if [ ! -f "${sysupgrade_file}" ] && \
		[ ! -b "${boot_device}" ] && \
		[ ! -b "${root_device}" ] ; then
		return 1
	fi

	local boot_directory="/boot"
	# make sure /boot directory is exist
	mkdir -p "${boot_directory}"
	# mount boot device to temporary directory
	mount -t "vfat" "${boot_device}" "${boot_directory}"
	# checks for:
	# 1. kernel file is exist
	# 2. kernel file is not a symlink
	# 3. kernel checksum file is exist
	# 4. kernel checksum file is not a symlink
	# and moves current kernel and kernel checksum files to files with .previous postfix
	if [ -f "${boot_directory}/${kernel_file}" ] && \
		[ ! -L "${boot_directory}/${kernel_file}" ] && \
		[ -f "${boot_directory}/${kernel_checksum_file}" ] && \
		[ ! -L "${boot_directory}/${kernel_checksum_file}" ] ; then
		mv "${kernel_file}" "${kernel_file}.previous"
		mv "${kernel_checksum_file}" "${kernel_checksum_file}.previous"
	fi

	echo "copying kernel to ${boot_directory}/${kernel_file}"
	# unpacks sysupgrade kernel file
	tar xf "${sysupgrade_file}" "${board_dir}/kernel" -O > "${kernel_file}"
	# creates md5 checksum for kernel file
	md5sum "${kernel_file}" | cut -f1 -d " " > "${kernel_checksum_file}"

	echo "flashing rootfs to ${root_device}"
	# write overlayfs file system over root device
	tar xf "${sysupgrade_file}" "${board_dir}/root" -O | dd of="${root_device}" bs=4096

	sync
	umount "${boot_directory}"
	return 0
}

platform_do_upgrade() {
	local sysupgrade_file="${1}"
	local board="$(board_name)"
	local kernel_file="vmlinux.64"
	local boot_device
	local root_device

	case "${board}" in
		er)
			boot_device="/dev/mmcblk0p1"
			root_device="/dev/mmcblk0p2"
			;;
		erlite)
			boot_device="/dev/sda1"
			root_device="/dev/sda2"
			;;
		itus,shield-router)
			kernel_file="ItusrouterImage"
			boot_device="/dev/mmcblk1p1"
			root_device="/dev/mmcblk1p2"
			;;
		*)
			return 1
	esac

	# checks if:
	# 1. boot device variable is not empty
	# 2. boot device variable points to actual boot device
	# 3. root device variable is not empty
	# 4. root device variable points to actual root device
	# and flashes firmware
	if [ ! -z "${boot_device}" ] && \
		[ -b "${boot_device}" ] && \
		[ ! -z "${root_device}" ] && \
		[ -b "${root_device}" ] ; then
		platform_do_flash "${sysupgrade_file}" "${kernel_file}" "${boot_device}" "${root_device}"
	fi

	return 0
}

platform_check_image() {
	local sysupgrade_file="${1}"
	local board="$(board_name)"
	# find a sysupgrade directory by looking inside sysupgrade file
	local sysupgrade_directory="$(tar tf ${sysupgrade_file} | awk -F '/' '/^sysupgrade/ {print $1; exit}')"
	# checks if sysupgrade directory variable is empty and exits with code 1
	[ -z "${sysupgrade_directory}" ] && return 1

	case "${board}" in
		er | \
		erlite | \
		itus,shield-router)
			# checks if:
			# 1. sysupgrade kernel file length is 0
			# 2. sysupgrade rootfs file length is 0
			# and exits with code 1
			local kernel_length="$(tar xf ${sysupgrade_file} ${sysupgrade_directory}/kernel -O | wc -c 2> /dev/null)"
			local rootfs_length="$(tar xf ${sysupgrade_file} ${sysupgrade_directory}/root -O | wc -c 2> /dev/null)"
			if [ "${kernel_length}" = 0 ] || [ "${rootfs_length}" = 0 ] ; then
				echo "The upgrade image is corrupt."
				return 1
			fi
			return 0
			;;
	esac

	echo "Sysupgrade is not yet supported on ${board}."
	return 1
}
