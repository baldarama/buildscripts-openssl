#!/bin/bash
set -e

OPENSSL_VERSION="1.0.2d"

# Retrieve NDK path to use
ndk_build_cmd=`which ndk-build`
ndk_dir=$(dirname $ndk_build_cmd)
if [ "$ndk_dir" == "" ]
then
  echo "Please specify a valid NDK path."
  exit 1
fi

# Create dist folder
BUILD_DIR=`pwd`

pushd $BUILD_DIR
export BINDIR=$BUILD_DIR/sysroot
export LOGDIR=$BUILD_DIR/log/droid
export TMPDIR=$BUILD_DIR/tmp
popd

rm -rf $LOGDIR
mkdir -p $LOGDIR
mkdir -p $TMPDIR

pushd $TMPDIR

export ANDROID_API_LEVEL="14"
export ARM_TARGET="armv7"

if [ -z $TOOLCHAIN_VERSION ]
then
	export TOOLCHAIN_VERSION="4.8"
fi

PLATFORMS="x86 arm-linux-androideabi"

for PLATFORM in ${PLATFORMS}
do
	echo "Creating toolchain for platform ${PLATFORM}..."

	if [ ! -d "${TMPDIR}/droidtoolchains/${PLATFORM}" ]
	then
		if [ "Darwin" == `uname -s` ]; then
			sys="darwin-x86_64"
		elif [ "Linux" == `uname -s` ]; then
			sys="linux-x86"
		fi

		$NDK/build/tools/make-standalone-toolchain.sh \
			--verbose \
			--system=${sys} \
			--platform=android-${ANDROID_API_LEVEL} \
			--toolchain=${PLATFORM}-${TOOLCHAIN_VERSION} \
			--install-dir=${TMPDIR}/droidtoolchains/${PLATFORM}
	fi
done

# Build projects
for PLATFORM in ${PLATFORMS}
do
	LOGPATH="${LOGDIR}/${PLATFORM}"
	ROOTDIR="${TMPDIR}/build/droid/${PLATFORM}"

	mkdir -p "${ROOTDIR}"

	if [ "${PLATFORM}" == "arm-linux-androideabi" ]
	then
		export ARCH=${ARM_TARGET}
		export DROIDTOOLS=${TMPDIR}/droidtoolchains/${PLATFORM}/bin/${PLATFORM}
	else
		export ARCH="i686-linux-android"
		export DROIDTOOLS=${TMPDIR}/droidtoolchains/${PLATFORM}/bin/${ARCH}
	fi

	export PLATFORM=${PLATFORM}
	export SYSROOT=${TMPDIR}/droidtoolchains/${PLATFORM}/sysroot


  cd ${BUILD_DIR}

  if [ ! -e "openssl-${OPENSSL_VERSION}.tar.gz" ]
  then
    curl -O -L http://openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
  fi

  rm -rf "openssl-${OPENSSL_VERSION}"
  tar xvf openssl-${OPENSSL_VERSION}.tar.gz

  # Build
  pushd "openssl-${OPENSSL_VERSION}"

  DROID_GCC_LIBS=${TMPDIR}/droidtoolchains/${PLATFORM}/lib/gcc/arm-linux-androideabi/4.8

  export CC=${DROIDTOOLS}-gcc
  export LD=${DROIDTOOLS}-ld
  export CPP=${DROIDTOOLS}-cpp
  export CXX=${DROIDTOOLS}-g++
  export AR=${DROIDTOOLS}-ar
  export AS=${DROIDTOOLS}-as
  export NM=${DROIDTOOLS}-nm
  export STRIP=${DROIDTOOLS}-strip
  export CXXCPP=${DROIDTOOLS}-cpp
  export RANLIB=${DROIDTOOLS}-ranlib
  export LDFLAGS="-Os -dynamiclib -fPIC -nostdlib -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${DROID_GCC_LIBS} -L${ROOTDIR}/lib -lc -lgcc"
  export CFLAGS="-Os -pipe -UOPENSSL_BN_ASM_PART_WORDS -isysroot ${SYSROOT} -I${ROOTDIR}/include "
  export CXXFLAGS="-Os -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include"

  ./Configure no-dtls no-ssl2 no-ssl3 no-krb5 -DOPENSSL_NO_HEARTBEATS zlib-dynamic --openssldir=${ROOTDIR} linux-generic32 no-hw

  mv "Makefile" "Makefile~"
  sed "s/\.so\.\$(SHLIB_MAJOR).\$(SHLIB_MINOR)/\.so/" Makefile~ > Makefile~1
  sed "s/\$(SHLIB_MAJOR).\$(SHLIB_MINOR)//" Makefile~1 > Makefile

  make CC="${CC}" CFLAG="${CFLAGS}" SHARED_LDFLAGS="${LDFLAGS}"
  make install
  popd

  # Clean up
  rm -rf "openssl-${OPENSSL_VERSION}"
	rm -rf "${ROOTDIR}/bin"
	rm -rf "${ROOTDIR}/certs"
	rm -rf "${ROOTDIR}/libexec"
	rm -rf "${ROOTDIR}/man"
	rm -rf "${ROOTDIR}/misc"
	rm -rf "${ROOTDIR}/private"
	rm -rf "${ROOTDIR}/sbin"
	rm -rf "${ROOTDIR}/share"
	rm -rf "${ROOTDIR}/openssl.cnf"

done

mkdir -p ${BINDIR}/include
cp -r ${TMPDIR}/build/droid/arm-linux-androideabi/include ${BINDIR}/
mkdir -p ${BINDIR}/lib/${ARM_TARGET}

cp ${TMPDIR}/build/droid/arm-linux-androideabi/lib/*.a ${BINDIR}/lib/${ARM_TARGET}
cp ${TMPDIR}/build/droid/arm-linux-androideabi/lib/*.la ${BINDIR}/lib/${ARM_TARGET}

(cd ${TMPDIR}/build/droid/arm-linux-androideabi/lib && tar cf - *.so ) | ( cd ${BINDIR}/lib/${ARM_TARGET} && tar xfB - )

popd
