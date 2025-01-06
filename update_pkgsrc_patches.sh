#!/bin/sh

# Usage: ./update_pkgsrc_patches.sh [-d <pkgsrc/[chromium,electron32,etc]/path> -o <pkgsrc/workobj/dir>]
# Example: ./update_pkgsrc_patches.sh -d /usr/pkgsrc/wip/chromium -o /mnt/wrkobjdir
# Example: ./update_pkgsrc_patches.sh -d /usr/pkgsrc/wip/electron32 -o /mnt/wrkobjdir

# Unwanted modifications:
_unwanted=" third_party/rust-src/src/tools/enzyme/enzyme/benchmarks/ReverseMode/lstm/data/lstm_full.txt"

# func
# pkgsrcpath <path>
ppath() {
    _p1=$(dirname "$1")
    _category=$(basename "$_p1")
    _pkgname=$(basename "$1")
    echo "$_category/$_pkgname"
}

# die [what]
die () {
    _errc=$?
    if [ -n "$1" ]; then
        echo ">>> $1 failed ($_errc)"
    fi
    exit $_errc
}

# Check arguments
if [ $# -ne 0 ] && [ $# -ne 2 ] && [ $# -ne 4 ]; then
        echo "Error: wrong args"
        echo "Usage: ./update_pkgsrc_patches.sh [-d <pkgsrc/package/path> -o <pkgsrc/workobj/dir>]"
        exit 1
fi

for _arg in "$@"; do
    case "$_arg" in
        -d)
            _path="$2"
            shift 2
            ;;
        -o)
            _obj="$2"
            shift 2
            ;;
    esac
done

_kaiju_repo=$(pwd)

# Check pkgsrc's package path
if [ -n "$_path" ]; then
    if [ ! -d "$_path" ]; then
        echo "Error: $_path is not valid"
        exit 1
    fi
else
    echo "Error: can't set pkgsrc's chromium path"
    exit 1
fi

_ppath=$(ppath "$_path")
echo ">>> Used $_pkgname pkgrsc path: $_path"

# Set pkgsrc's workobjdir path
if [ -n "$_obj" ]; then
    if [ ! -d "$_obj" ]; then
        echo "Error: $_obj is not valid"
        exit 1
    else
        _objd="$_obj/$_ppath/work"
    fi
else
    _objd="$_path/work"
fi

echo ">>> Used workobjdir: $_objd"

# Clean obj dir
if [ -d "$_objd" ]; then
    cd "$_path" || die
    make clean || die
fi

# Clean pkgsrc package/patches
echo ">>> Remove old patches"
cd "$_path" || die
rm patches/patch-*

# Apply all-in patch in pkgsrc workdir
# Create patches in package/patches
# Fix pkglint error: Each patch must be documented
make makesum || die "make makesum"
make extract || die "make extract"
echo ">>> Apply new patchset on source"
cd "$_objd"/"$_pkgname"-* || die
for _unwant in $_unwanted; do
    if [ -f "$_unwant" ]; then
        # rename vanilla files from *.orig to *.origy to avoid match by mkpatches
        mv "$_unwant".orig "$_unwant".origy
    fi
done
patch -p1 -s -i "$_kaiju_repo"/patches/"$_pkgname"/nb.patch || die patch
echo ">>> Generate new patches with mkpatches"
cd "$_path" || die
mkpatches || die mkpatches
rm patches/*.orig
rm patches/*Cargo.toml
for _patch in patches/patch-*; do
    if [ "$_pkgname" = "chromium" ]; then
        # shellcheck disable=SC3003
        sed -i'' \
            -e $'3i\\\n* Part of patchset to build chromium on NetBSD\n' \
            -e $'3i\\\n* Based on OpenBSD\'s chromium patches, and\n' \
            -e $'3i\\\n  pkgsrc\'s qt5-qtwebengine patches\n' \
            -e $'3i\\\n\n' \
            "$_patch" || die sed
    else
        # shellcheck disable=SC3003
        sed -i'' \
            -e $'3i\\\n* Part of patchset to build electron on NetBSD\n' \
            -e $'3i\\\n* Based on OpenBSD\'s chromium patches, and\n' \
            -e $'3i\\\n  FreeBSD\'s electron patches\n' \
            -e $'3i\\\n\n' \
            "$_patch" || die sed
    fi
done

# Update pkgsrc's distinfo
# Clean pkgsrc's workdir
echo ">>> Generate the checksums for the patch files"
make makepatchsum || die
make clean || die

exit 0
