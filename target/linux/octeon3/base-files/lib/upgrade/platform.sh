platform_copy_config() {
	local board="$(board_name)"
        local type="vfat"
        local device

	case "${board}" in
		ubnt,edgerouter-4 |\
		ubnt,edgerouter-12)
			device="/dev/mmcblk0p1"
			;;
	esac

	if [ ! -z "${device}" ] ; then
		mount -t "${type}" "${device}" /mnt
		cp -af "${UPGRADE_BACKUP}" "/mnt/${BACKUP_FILE}"
		umount /mnt
	fi
}

emmc_do_upgrade() {
	local sysupgrade_file="${1}"
	local device="${2}"
	local board_dir=$(tar tf "${sysupgrade_file}" | grep -m 1 '^sysupgrade-.*/$')
	board_dir=${board_dir%/}
	[ -n "$board_dir" ] || return 1

	mkdir -p /boot
	mount -t "vfat" "${device}p1" /boot
	[ -f /boot/vmlinux.64 -a ! -L /boot/vmlinux.64 ] && {
		mv /boot/vmlinux.64 /boot/vmlinux.64.previous
		mv /boot/vmlinux.64.md5 /boot/vmlinux.64.md5.previous
	}
	echo "copying kernel to ${device}p1"
	tar xf "${sysupgrade_file}" "${board_dir}/kernel" -O > /boot/vmlinux.64
	md5sum /boot/vmlinux.64 | cut -f1 -d " " > /boot/vmlinux.64.md5

	echo "flashing rootfs to ${device}p2"
	tar xf "${sysupgrade_file}" "${board_dir}/root" -O | dd of="${device}p2" bs=4096

	sync
	umount /boot
}

platform_do_upgrade() {
	local sysupgrade_file="${1}"
	local board="$(board_name)"

	case "${board}" in
		ubnt,edgerouter-4 |\
		ubnt,edgerouter-12)
			emmc_do_upgrade "${sysupgrade_file}" "/dev/mmcblk0"
			;;
		*)
			return 1
	esac

	return 0
}

platform_check_image() {
	local board="$(board_name)"
	local tar_file="${1}"

	local board_dir=$(tar tf "$tar_file" | grep -m 1 '^sysupgrade-.*/$')
	board_dir=${board_dir%/}
	[ -n "$board_dir" ] || return 1


	case "${board}" in
		ubnt,edgerouter-4 | \
		ubnt,edgerouter-12)
			local kernel_length=$(tar xf $tar_file $board_dir/kernel -O | wc -c 2> /dev/null)
			local rootfs_length=$(tar xf $tar_file $board_dir/root -O | wc -c 2> /dev/null)
			[ "$kernel_length" = 0 -o "$rootfs_length" = 0 ] && {
				echo "The upgrade image is corrupt."
				return 1
			}
			return 0
			;;
	esac

	echo "Sysupgrade is not yet supported on $board."
	return 1
}
