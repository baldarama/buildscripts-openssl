#!/bin/sh


VERSION="1.0.2d"													      #
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`                         #


CURRENTPATH=`pwd`
ARCHS="armv7 arm64 i386 x86_64"
DEVELOPER=`xcode-select -print-path`
ADDITIONAL_CONFIG="no-dtls no-ssl2 no-ssl3 no-krb5 -DOPENSSL_NO_HEARTBEATS "

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $DEVELOPER in
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac

case $CURRENTPATH in
     *\ * )
           echo "Your path contains whitespaces, which is not supported by 'make install'."
           exit 1
          ;;
esac

set -e
if [ ! -e OpenSSL_1_0_2-stable.zip ]; then
	echo "Downloading openssl-${VERSION}.tar.gz"
  curl -O -L http://openssl.org/source/openssl-${VERSION}.tar.gz
else
	echo "Using openssl-${VERSION}.tar.gz"
fi

rm -rf openssl-${VERSION}
rm -rf src
mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"


tar xvf openssl-${VERSION}.tar.gz
mv openssl-${VERSION} src/openssl-${VERSION}
cd "${CURRENTPATH}/src/openssl-${VERSION}"


for ARCH in ${ARCHS}
do
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
	then
		PLATFORM="iPhoneSimulator"
	else
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		PLATFORM="iPhoneOS"
	fi

	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"

	echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."

	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

	set +e
    if [[ "$VERSION" =~ 1.0.0. ]]; then
        ./Configure BSD-generic32 ${ADDITIONAL_CONFIG} --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
	elif [ "${ARCH}" == "x86_64" ]; then
	    ./Configure darwin64-x86_64-cc ${ADDITIONAL_CONFIG} --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
    else
	    ./Configure iphoneos-cross ${ADDITIONAL_CONFIG} --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
    fi

    if [ $? != 0 ];
    then
    	echo "Problem while configure - Please check ${LOG}"
    	exit 1
    fi

	# add -isysroot to CC=
	# add "-target arm-apple-ios-simulator" when building arm iphone simulator
	sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=7.0 !" "Makefile"

	make -j4 >> "${LOG}" 2>&1

	if [ $? != 0 ];
    then
    	echo "Problem while make - Please check ${LOG}"
    	exit 1
    fi

    set -e
	make install >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libssl.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libssl.a -output ${CURRENTPATH}/lib/libssl.a
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libcrypto.a -output ${CURRENTPATH}/lib/libcrypto.a

mkdir -p ${CURRENTPATH}/include
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/openssl ${CURRENTPATH}/include/
echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src/openssl-${VERSION}
echo "Done."
