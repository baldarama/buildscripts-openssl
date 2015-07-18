LOCAL_PATH := $(call my-dir)
LOCAL_PATH := $(subst //,/,$(LOCAL_PATH))

include $(CLEAR_VARS)

ROOT_DIR=$(LOCAL_PATH)/../..
MY_MODULE_DIR       := $(LOCAL_PATH)/..

LOCAL_MODULE        := opus

# silk
include silk_sources.mk
LOCAL_C_INCLUDES += silk
LOCAL_C_INCLUDES += silk/fixed
LOCAL_SRC_FILES += $(SILK_SOURCES:%=%)
LOCAL_SRC_FILES += $(SILK_SOURCES_FIXED:%=%)
ifeq ($(TARGET_ARCH_ABI),$(filter $(TARGET_ARCH_ABI), x86 x86_64))
#LOCAL_C_INCLUDES += silk/x86
#LOCAL_C_INCLUDES += silk/fixed/x86
#LOCAL_SRC_FILES += $(SILK_SOURCES_FIXED_SSE4_1:%=%)
#LOCAL_SRC_FILES += $(SILK_SOURCES_SSE4_1:%=%)
endif

#celt
include celt_sources.mk
LOCAL_C_INCLUDES += celt
LOCAL_SRC_FILES += $(CELT_SOURCES:%=%)
ifeq ($(TARGET_ARCH_ABI),$(filter $(TARGET_ARCH_ABI), x86 x86_64))
#LOCAL_C_INCLUDES += celt/x86
#LOCAL_SRC_FILES += $(CELT_SOURCES_SSE:%=%)
#LOCAL_SRC_FILES += $(CELT_SOURCES_SSE4_1:%=%)
endif

#opus
include opus_sources.mk
LOCAL_C_INCLUDES += include
LOCAL_SRC_FILES += $(OPUS_SOURCES:%=%)
LOCAL_SRC_FILES += $(OPUS_SOURCES_FLOAT:%=%)


LOCAL_CFLAGS    := -DNULL=0 -DSOCKLEN_T=socklen_t -DLOCALE_NOT_USED -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64
LOCAL_CFLAGS    += -Drestrict='' -D__EMX__ -DOPUS_BUILD -DFIXED_POINT -DUSE_ALLOCA -DHAVE_LRINT -DHAVE_LRINTF -O3 -fno-math-errno

LOCAL_CPPFLAGS  := -DBSD=1
LOCAL_CPPFLAGS  += -ffast-math -O3 -funroll-loops

ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
	EXTRA_CFLAGS := -march=armv7-a -mfloat-abi=softfp -mfpu=neon
endif

ifeq ($(TARGET_ARCH_ABI),x86)
	EXTRA_CFLAGS := -ffunction-sections -funwind-tables  -no-canonical-prefixes
#	EXTRA_CFLAGS += -DOPUS_X86_MAY_HAVE_SSE2
endif

LOCAL_CFLAGS += -fomit-frame-pointer -fstrict-aliasing -funswitch-loops $(EXTRA_CFLAGS)

include $(BUILD_STATIC_LIBRARY)
