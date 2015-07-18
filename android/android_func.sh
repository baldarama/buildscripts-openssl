#check ndk-build
which ndk-build &>/dev/null
if [ $? -eq 0 ]; then
    echo "ndk-build found" &>/dev/null
else
    echo "ndk-build command not found."
    exit 1
fi

ndk_build_cmd=`which ndk-build`
ndk_dir=$(dirname $ndk_build_cmd)
BUILD_DIR=$PWD

TOOLCHAIN_DIR=$BUILD_DIR/toolchain
INST_DIR=$TOOLCHAIN_DIR/sysroot
TOP_DIR=$TOOLCHAIN_DIR
export TOP_DIR
export BUILD_DIR
echo "TOP_DIR=$TOP_DIR build_dir=$BUILD_DIR"

if [ ! -e $TOOLCHAIN_DIR ]; then
    mkdir -p $TOOLCHAIN_DIR
    mkdir -p $INST_DIR
    chmod -R +rw $TOOLCHAIN_DIR
fi

function copy_install_dir
{
    src="$1"
    target_dir="$2"
    for i in `ls ${src}/lib*.a`
    do
        copy_install $i $target_dir
    done;
}

function copy_install
{
    src="$1"
    target_dir="$2"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
        chmod +rw "$target_dir"
    fi

    cp $src $target_dir
}

function build_only
{
    start_time=$(date +"%s")

    echo "--- build $1 ---"
    adir="$1"
    if [ -z "$2" ]; then
        artefact=`echo $1 | sed "s/^lib//g"`
    else
        artefact="$2"
    fi

    cd $adir/android &>/dev/null
    if [ ! -f "libs/armeabi-v7a/lib${artefact}.so" ]; then
        echo "Building $artefact library for arm-v7a and x86..."
        $ndk_build_cmd -j8
        if [ \( ! -f "libs/armeabi-v7a/lib${artefact}.so" \) -o \( ! -f "libs/x86/lib${artefact}.so" \) ]; then
            $ndk_build_cmd
        fi
    fi

    time_diff $start_time       # time diff
}

function ndk_clean
{
 start_time=$(date +"%s")

    echo "--- Clean: $1 ---"
    adir="$1"
    artefact=`echo $1 | sed "s/^lib//g"`
    cd $adir/android &>/dev/null
    $ndk_build_cmd clean
    rm -fr obj
    cd $BUILD_DIR &>/dev/null

    time_diff $start_time
}

function ndk_build
{
    build_only "$1"

    if [ ! -f "$INST_DIR/lib/armeabi-v7a/lib${artefact}.a" -o ! -f "$INST_DIR/lib/armeabi-v7a/lib${artefact}.so" ]; then
        echo "copy lib${artefact}_static.a to $INST_DIR/lib/armeabi-v7a/lib${artefact}.a"
        if [ ! -d "$INST_DIR/lib/armeabi-v7a" ]; then
            mkdir -p "$INST_DIR/lib/armeabi-v7a"
        fi
        cp obj/local/armeabi-v7a/lib${artefact}_static.a $INST_DIR/lib/armeabi-v7a/lib${artefact}.a
        copy_install "libs/armeabi-v7a/lib${artefact}.so" "$INST_DIR/lib/armeabi-v7a"
    fi

    if [ ! -f "$INST_DIR/lib/x86/lib${artefact}.a" -o ! -f "$INST_DIR/lib/x86/lib${artefact}.so" ]; then
        if [ ! -d "$INST_DIR/lib/x86" ]; then
            mkdir -p "$INST_DIR/lib/x86"
        fi
        cp obj/local/x86/lib${artefact}_static.a $INST_DIR/lib/x86/lib${artefact}.a
        copy_install "libs/x86/lib${artefact}.so" "$INST_DIR/lib/x86"
    fi

    cd $BUILD_DIR &>/dev/null
}
