include $(TOPDIR)/rules.mk

ARCH:=mips64
BOARD:=octeon3
BOARDNAME:=Cavium Networks Octeon 3
FEATURES:=fpu pci pcie ramdisk squashfs usb
CPU_TYPE:=octeon3

KERNEL_PATCHVER:=5.4
KERNEL_TESTING_PATCHVER:=5.4

define Target/Description
	Build firmware images for Cavium Networks Octeon 3 based boards.
endef

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += mkf2fs e2fsprogs

$(eval $(call BuildTarget))
