#!/bin/sh

# Usage: ./update_vanila_chromium.sh <chromium version>
# Example: ./update_vanilla_chromium.sh 120.6099.216

c_tarball_url="https://commondatastorage.googleapis.com/chromium-browser-official"
#c_tarball_url="https://nerd.hu/distfiles"

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
else
	echo "Error: not set chromium version"
    echo "Usage: ./update_vanilla.sh <chromium version>"
	exit 1
fi

# get chromium
if [ ! -f "../chromium-${c_ver}-download_done" ]; then
    cd .. || die
    curl "${c_tarball_url}/chromium-${c_ver}.tar.xz" -o "chromium-${c_ver}.tar.xz" || die "curl chromium"
    #curl "${c_tarball_url}/chrome-gn-${c_ver}-src.tar.xz" -o "chrome-gn-${c_ver}-src.tar.xz" || die "curl chrome-gn"
    curl "${c_tarball_url}/chromium-${c_ver}.tar.xz.hashes" -o "chromium-${c_ver}.tar.xz.hashes" || die "curl hashes"
    sed -n 's|sha256 *\(.*\)|\1|p' "chromium-${c_ver}.tar.xz.hashes" | sha256 -c || die checksum
    cd "$_startdir" || die
    touch "../chromium-${c_ver}-download_done"
fi

# extract tarballs
if [ ! -f "../chromium-${c_ver}-extract_done" ]; then
    cd .. || die
    mkdir "chromium-netbsd-${c_ver}" || die
    tar -xJf "chromium-${c_ver}.tar.xz" --strip-components=1 -C "chromium-netbsd-${c_ver}" || die "extract chromium"
    #tar -xJf "chrome-gn-${c_ver}-src.tar.xz" --strip-components=1 -C "chromium-netbsd-${c_ver}" || die "extract chrome-gn"
    sed -i'' 's/swiftshader/swiftshaderXXX/g' "chromium-netbsd-${c_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "chromium-netbsd-${c_ver}/third_party/vulkan-deps/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "chromium-netbsd-${c_ver}/third_party/.gitignore"
    cd "$_startdir" || die
    touch "../chromium-${c_ver}-extract_done"
fi

# init git repo
if [ ! -f "../chromium-${c_ver}-init_done" ]; then
    cd "../chromium-netbsd-${c_ver}" || die
    git init || die
    git add . || die
    git commit -m "Chromium-${c_ver}" || die
    cd "$_startdir" || die
    touch "../chromium-${c_ver}-init_done"
fi

# Apply openbsd patchset in wip branch
if [ ! -f "../chromium-${c_ver}-obpatches_done" ]; then
    if [ -d "../openbsd-ports/www/chromium/patches" ]; then
        p_dir="../openbsd-ports/www/chromium/patches"
    elif [ -d "../ports/www/chromium/patches" ]; then
        p_dir="../ports/www/chromium/patches"
    else
        echo "Error: not found openbsd ports tree"
        exit 1
    fi

    cd "${p_dir}/../../.." || die
    git pull || die "OpenBSD-ports update: "

    cd "../chromium-netbsd-${c_ver}" || die
    for _patch in "$p_dir"/patch-*; do
        if [ -e "$_patch" ]; then
            patch -Np0 -i "$_patch" || die "Apply OpenBSD patches"
        fi
    done

    git add . || die
    git commit -m "Apply OpenBSD patchset" || die
    cd "$_startdir" || die
    touch "../chromium-${c_ver}-obpatches_done"
fi

# Apply NetBSD delta patch
cd "../chromium-netbsd-${c_ver}" || die
if [ -e "../kaiju/patches/chromium/nb-delta.patch" ]; then

    # clean distfiles, status files
    rm "../chromium-${c_ver}.tar.xz" || die
    #rm "../chrome-gn-${c_ver}-src.tar.xz" || die
    rm "../chromium-${c_ver}.tar.xz.hashes" || die
    rm "../chromium-${c_ver}-download_done"
    rm "../chromium-${c_ver}-extract_done"
    rm "../chromium-${c_ver}-init_done"
    rm "../chromium-${c_ver}-obpatches_done"

    git apply --reject ../kaiju/patches/chromium/nb-delta.patch || die "Apply NetBSD delta patch"
fi

exit 0
