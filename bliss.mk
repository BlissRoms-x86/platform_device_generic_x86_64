# Boot animation
TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1080

# Release name
PRODUCT_RELEASE_NAME := android_x86_64

# Inherit device configuration
$(call inherit-product, $(LOCAL_PATH)/android_x86_64.mk)
