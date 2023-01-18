#
# Product-specific compile-time definitions.
#

# The generic product target doesn't have any hardware-specific pieces.
TARGET_NO_BOOTLOADER := true
TARGET_CPU_ABI := x86_64
TARGET_ARCH := x86_64
TARGET_ARCH_VARIANT := x86_64

TARGET_2ND_CPU_ABI := x86
TARGET_2ND_ARCH := x86
TARGET_2ND_ARCH_VARIANT := x86_64

ifeq ($(USE_LIBNDK_TRANSLATION_NB),true)
include vendor/google/emu-x86/board/native_bridge_arm_on_x86.mk
endif

ifeq ($(USE_CROS_HOUDINI_NB),true)
include vendor/google/chromeos-x86/board/native_bridge_arm_on_x86.mk
endif

ifeq ($(ANDROID_USE_INTEL_HOUDINI),true)
include vendor/intel/proprietary/houdini/board/native_bridge_arm_on_x86.mk
endif

ifeq ($(ANDROID_USE_NDK_TRANSLATION),true)
include vendor/google/proprietary/ndk_translation-prebuilt/board/native_bridge_arm_on_x86.mk
endif

TARGET_CPU_ABI_LIST_64_BIT := $(TARGET_CPU_ABI) $(NATIVE_BRIDGE_ABI_LIST_64_BIT)
TARGET_CPU_ABI_LIST_32_BIT := $(TARGET_2ND_CPU_ABI) $(NATIVE_BRIDGE_ABI_LIST_32_BIT)
TARGET_CPU_ABI_LIST := $(TARGET_CPU_ABI) $(TARGET_2ND_CPU_ABI) $(NATIVE_BRIDGE_ABI_LIST_32_BIT) $(NATIVE_BRIDGE_ABI_LIST_64_BIT)

TARGET_USERIMAGES_USE_EXT4 := true
BOARD_USERDATAIMAGE_PARTITION_SIZE := 576716800
BOARD_CACHEIMAGE_PARTITION_SIZE := 69206016
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 512
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true

include device/generic/common/BoardConfig.mk
