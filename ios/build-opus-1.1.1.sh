#!/bin/sh

MINIOSVERSION="7.0"
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

OPT_CFLAGS="-Ofast -flto -DFLOAT_APPROX"
OPT_LDFLAGS="-flto"
OPT_CONFIG_ARGS=""

if [ ! -d "opus.git" ]; then
echo "Cloning repository from git://git.opus-codec.org/opus.git"
    git clone git://git.opus-codec.org/opus.git opus.git
fi

cd opus.git
./autogen.sh
pwd

ARCHS="armv7 arm64 i386 x86_64"

DEVELOPER=`xcode-select -print-path`

REPOROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
mkdir -p ${REPOROOT}/lib

LIBPATH=${REPOROOT}/lib
mkdir -p ${LIBPATH}/include


for ARCH in ${ARCHS}
do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
        PLATFORM="iPhoneSimulator"
        EXTRA_CFLAGS="-arch ${ARCH}"
        EXTRA_CONFIG=""
    else
        PLATFORM="iPhoneOS"
        if [ "${ARCH}" == "armv7" ]; then
        	EXTRA_CFLAGS="-mfpu=neon -arch ${ARCH}"
        	EXTRA_CONFIG="--host=arm-apple-darwin --enable-intrinsics --enable-rtcd --enable-asm --enable-fixed-point"
        elif [ "${ARCH}" == "arm64" ]; then
        	EXTRA_CFLAGS="-arch ${ARCH}"
        	EXTRA_CONFIG="--host=arm-apple-darwin --enable-intrinsics --disable-rtcd"
        else
        	EXTRA_CFLAGS="-mfpu=neon -arch ${ARCH}"
        	EXTRA_CONFIG="--host=arm-apple-darwin --enable-intrinsics --enable-rtcd --enable-asm --enable-fixed-point"
        fi
    fi
	mkdir -p "${LIBPATH}/${PLATFORM}-${ARCH}.sdk"
	./configure --disable-shared --enable-static --disable-doc --enable-float-approx --disable-extra-programs ${EXTRA_CONFIG} \
    --prefix="${LIBPATH}/${PLATFORM}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -L${LIBPATH}" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} -DFLOAT_APPROX=1 ${OPT_CFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -I${LIBPATH}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \
    # Build the application and install it to the fake SDK intermediary dir
    # we have set up. Make sure to clean up afterward because we will re-use
    # this source tree to cross-compile other targets.
	make
	make install
	make clean
done

xcrun -sdk iphoneos lipo -create -arch armv7 lib/iPhoneOS-armv7.sdk/lib/libopus.a -arch arm64 lib/iPhoneOS-arm64.sdk/lib/libopus.a  -arch i386 lib/iPhoneSimulator-i386.sdk/lib/libopus.a -arch x86_64 lib/iPhoneSimulator-x86_64.sdk/lib/libopus.a -output libopus.a
