include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define Build/append-dtb-to-elf
	$(TARGET_CROSS)objcopy --update-section .appended_dtb=$(KDIR)/image-$(SOC)_$(DEVICE_NAME).dtb $@
endef

define Device/Default
  PROFILES = Default $$(DEVICE_NAME)
  DEVICE_DTS_DIR := ../dts
  KERNEL_NAME := vmlinux.elf
  KERNEL_INITRAMFS_NAME := vmlinux-initramfs.elf
  KERNEL := kernel-bin | append-dtb-to-elf
  KERNEL_DEPENDS = $$(wildcard $(DTS_DIR)/$$(SOC)_$(1).dts)
  IMAGES := sysupgrade.tar
  IMAGE/sysupgrade.tar/squashfs := append-rootfs | pad-extra 128k | sysupgrade-tar rootfs=$$$$@
  IMAGE/sysupgrade.tar := sysupgrade-tar
endef

define Device/generic
  DEVICE_VENDOR := Generic
  DEVICE_MODEL := Octeon 3
  FILESYSTEMS := ext4
endef
TARGET_DEVICES += generic

define Device/ubnt_edgerouter-4
  DEVICE_VENDOR := Ubiquiti
  DEVICE_MODEL := EdgeRouter 4
  SOC := cn7130
  DEVICE_DTS = $$(SOC)_$(1)
  DEVICE_PACKAGES += kmod-gpio-button-hotplug kmod-leds-gpio kmod-of-mdio kmod-usb3 kmod-usb-dwc3
endef
TARGET_DEVICES += ubnt_edgerouter-4

define Device/ubnt_edgerouter-12
  DEVICE_VENDOR := Ubiquiti
  DEVICE_MODEL := EdgeRouter 12
  SOC := cn7130
  DEVICE_DTS = $$(SOC)_$(1)
  DEVICE_PACKAGES += kmod-hwmon-adt7475 kmod-hwmon-tmp421 kmod-leds-gpio kmod-of-mdio kmod-usb3 kmod-usb-dwc3
endef
TARGET_DEVICES += ubnt_edgerouter-12

$(eval $(call BuildImage))
