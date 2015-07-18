APP_ABI := $(filter arm%,$(NDK_ALL_ABIS))

APP_OPTIM:=release
APP_ABI := armeabi-v7a x86
LOCAL_CPP_FEATURES := rtti features
APP_STL := gnustl_static
NDK_TOOLCHAIN_VERSION=4.8
