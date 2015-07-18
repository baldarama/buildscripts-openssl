#!/bin/bash
export ANDROID_NDK=`which ndk-build`
export PATH="$PATH:$ANDROID_NDK"

. android_func.sh

cd $TOOLCHAIN_DIR
if [ ! -d "opus" ]; then
    git clone git://git.opus-codec.org/opus.git
fi

cd $TOOLCHAIN_DIR/opus
if [ ! -f "$TOOLCHAIN_DIR/opus/obj/local/armeabi-v7a/libopus.a" ]; then
    echo "Building opus..."
    cd $TOOLCHAIN_DIR/opus
    mkdir -p $TOOLCHAIN_DIR/opus/jni
    ln -s $TOOLCHAIN_DIR/opus/src jni/
    ln -s $TOOLCHAIN_DIR/opus/include jni/
    ln -s $TOOLCHAIN_DIR/opus/silk jni/
    ln -s $TOOLCHAIN_DIR/opus/celt jni/
    ln -s $BUILD_DIR/Android.mk jni/
    ln -s $BUILD_DIR/Application.mk jni/

    ndk-build clean
    ndk-build -j4 LIBPATH=$TOOLCHAIN_DIR/opus APP_ABI="armeabi-v7a x86"
fi

if [ ! -d "$INST_DIR/lib/armeabi-v7a" ]; then
    mkdir -p "$INST_DIR/lib/armeabi-v7a"
fi
if [ ! -d "$INST_DIR/lib/x86" ]; then
    mkdir -p "$INST_DIR/lib/x86"
fi

cp $TOOLCHAIN_DIR/opus/obj/local/armeabi-v7a/libopus.a $INST_DIR/lib/armeabi-v7a/
cp $TOOLCHAIN_DIR/opus/obj/local/x86/libopus.a $INST_DIR/lib/x86/
