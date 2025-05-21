#!/bin/sh

# Usage: ./release_chromium_netbsd.sh <chromium version>
# Example: ./release_chromium_netbsd.sh 120.0.6099.216

# shellcheck source=kaiju.conf
. kaiju.conf

# func
# die [what]
die () {
    _errc=$?
    if [ -n "$1" ]; then
        echo ">>> $1 failed ($_errc)"
    fi
    exit $_errc
}

_startdir=$(pwd)

if [ "$1" != "" ]; then
	c_ver="$1"
    c_main=${c_ver%%.*}
else
	echo "Error: not set chromium version"
    echo "Usage: ./release_chromium_netbsd.sh <chromium version>"
	exit 1
fi

_c_rver=$(grep "$c_ver" electron.versions|cut -d: -f9)
c_tarball_url="https://github.com/tagattie/FreeBSD-Electron/releases/download/v${_c_rver}/"

# create workdir
mkdir -p "$tools_workdir" || die

# get sources
if [ ! -f "$tools_workdir/cn_release-${c_ver}-download_done" ]; then
    cd "$tools_workdir" || die
    echo "Download distfiles..."
    for c_num in 0 1 2; do
        if [ ! -f "$distfiles/chromium-${c_ver}.tar.xz.${c_num}" ]; then
            curl -L "${c_tarball_url}/chromium-${c_ver}.tar.xz.${c_num}" \
                 -o "chromium-${c_ver}.tar.xz.${c_num}" \
                 || die "curl chromium.${c_num}"
        fi
    done
    cd "$_startdir" || die
    touch "$tools_workdir/cn_release-${c_ver}-download_done"
fi

# extract tarballs
if [ ! -f "$tools_workdir/cn_release-${c_ver}-extract_done" ]; then
    cd "$tools_workdir" || die
    echo "Extract distfiles to ..."
    mkdir "chromium-netbsd-${c_ver}" || die
    cat "$distfiles"/chromium-"${c_ver}".tar.xz.? > "chromium-${c_ver}.tar.xz" || die "cat chromium.?"
    tar -xJf "chromium-${c_ver}.tar.xz" --strip-components=1 -C "chromium-netbsd-${c_ver}" || die "extract chromium"
    echo "*.rej" >> "chromium-netbsd-${c_ver}/.gitignore" 
    sed -i'' 's/swiftshader/swiftshaderXXX/g' "chromium-netbsd-${c_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "chromium-netbsd-${c_ver}/third_party/vulkan-deps/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "chromium-netbsd-${c_ver}/third_party/.gitignore"

    cd "$_startdir" || die
    touch "$tools_workdir/cn_release-${c_ver}-extract_done"
fi

# Apply NetBSD patch
if [ ! -f "$tools_workdir/cn_release-${c_ver}-patch_done" ]; then
    cd "$tools_workdir/chromium-netbsd-${c_ver}" || die
    patch -Np0 -i "$_startdir/patches/chromium${c_main}/nb.patch" || die "Apply NetBSD patches"

    cd "$_startdir" || die
    touch "$tools_workdir/cn_release-${c_ver}-patch_done"
fi

# tarball
if [ -f "$tools_workdir/cn_release-${c_ver}-patch_done" ]; then
    cd "$tools_workdir/chromium-netbsd-${c_ver}" || die
    _hasrej=0
    # shellcheck disable=SC2044
    for _rej in $(find . -type f -name "*.rej"); do
        if [ -e "$_rej" ]; then
            _hasrej=1
            echo "$_rej"
        fi
    done
    if [ "$_hasrej" = "1" ]; then
        echo ">>> Fix rejected patches, and run again"
        return 1
    fi

    cd ..
    tar -cJf "../chromium-netbsd-${c_ver}.tar.xz" "chromium-netbsd-${c_ver}" || die "create tarball"

    # clean distfiles, status files
    rm "../cn_release-${c_ver}-download_done"
    rm "../cn_release-${c_ver}-extract_done"
    rm "../cn_release-${c_ver}-patch_done"
fi

exit 0