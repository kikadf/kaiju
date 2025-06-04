#!/bin/sh

# Usage: ./update_vanila_chromium.sh <chromium version>
# Example: ./update_vanilla_chromium.sh 120.6099.216

_startdir=$(pwd)
. "$_startdir/kaiju.conf"

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

if [ "$1" != "" ]; then
	c_ver="$1"
else
	echo "Error: not set chromium version"
    echo "Usage: ./update_vanilla_chromium.sh <chromium version>"
	exit 1
fi

# create workdir
mkdir -p "$tools_workdir" || die

# get chromium
if [ ! -f "$tools_workdir/chromium-${c_ver}-download_done" ]; then
    cd "$tools_workdir" || die
    if [ ! -f "$distfiles/chromium-${c_ver}.tar.xz" ]; then
        curl "${c_tarball_url}/chromium-${c_ver}.tar.xz" -o "$distfiles/chromium-${c_ver}.tar.xz" || die "curl chromium"
    fi
    #curl "${c_tarball_url}/chrome-gn-${c_ver}-src.tar.xz" -o "chrome-gn-${c_ver}-src.tar.xz" || die "curl chrome-gn"
    curl "${c_tarball_url}/chromium-${c_ver}.tar.xz.hashes" -o "chromium-${c_ver}.tar.xz.hashes" || die "curl hashes"
    cd "$distfiles" || die
    sed -n 's|sha256 *\(.*\)|\1|p' "$tools_workdir/chromium-${c_ver}.tar.xz.hashes" | sha256 -c || die checksum
    cd "$_startdir" || die
    touch "$tools_workdir/chromium-${c_ver}-download_done"
fi

# extract tarballs
if [ ! -f "$tools_workdir/chromium-${c_ver}-extract_done" ]; then
    cd "$tools_workdir" || die
    mkdir "chromium-${c_ver}" || die
    tar -xJf "$distfiles/chromium-${c_ver}.tar.xz" --strip-components=1 -C "chromium-${c_ver}" || die "extract chromium"
    #tar -xJf "chrome-gn-${c_ver}-src.tar.xz" --strip-components=1 -C "chromium-${c_ver}" || die "extract chrome-gn"
    sed -i'' 's/swiftshader/swiftshaderXXX/g' "chromium-${c_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "chromium-${c_ver}/third_party/vulkan-deps/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "chromium-${c_ver}/third_party/.gitignore"
    cd "$_startdir" || die
    touch "$tools_workdir/chromium-${c_ver}-extract_done"
fi

# init git repo
if [ ! -f "$tools_workdir/chromium-${c_ver}-init_done" ]; then
    cd "$tools_workdir/chromium-${c_ver}" || die
    git init || die
    git add . || die
    git commit -m "Chromium-${c_ver}" || die
    cd "$_startdir" || die
    touch "$tools_workdir/chromium-${c_ver}-init_done"
fi

# Apply openbsd patchset in wip branch
if [ ! -f "$tools_workdir/chromium-${c_ver}-obpatches_done" ]; then
    cd "$tools_workdir" || die
    if [ ! -d "openbsd-ports" ]; then
        mkdir openbsd-ports || die
        git clone https://github.com/openbsd/ports.git openbsd-ports || die "clone OpenBSD-ports"
    else
        cd openbsd-ports || die
        git pull || die "OpenBSD-ports update: "
        cd ..
    fi
    if [ -d "openbsd-ports/www/chromium/patches" ]; then
        p_dir="../openbsd-ports/www/chromium/patches"
    else
        echo "Error: not found openbsd ports tree"
        exit 1
    fi

    cd "chromium-${c_ver}" || die
    for _patch in "$p_dir"/patch-*; do
        if [ -e "$_patch" ]; then
            patch -Np0 -i "$_patch" || die "Apply OpenBSD patches"
        fi
    done

    git add . || die
    git commit -m "Apply OpenBSD patchset" || die
    cd "$_startdir" || die
    touch "$tools_workdir/chromium-${c_ver}-obpatches_done"
fi

# Apply NetBSD delta patch
cd "$tools_workdir/chromium-${c_ver}" || die
if [ -e "$_startdir/patches/chromium/nb-delta.patch" ]; then

    # clean distfiles, status files
    #rm "../chromium-${c_ver}.tar.xz" || die
    #rm "../chrome-gn-${c_ver}-src.tar.xz" || die
    rm "../chromium-${c_ver}.tar.xz.hashes" || die
    rm "../chromium-${c_ver}-download_done"
    rm "../chromium-${c_ver}-extract_done"
    rm "../chromium-${c_ver}-init_done"
    rm "../chromium-${c_ver}-obpatches_done"

    git apply --reject "$_startdir/patches/chromium/nb-delta.patch" || die "Apply NetBSD delta patch"
fi

exit 0
