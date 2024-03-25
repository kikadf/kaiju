#!/bin/sh

# Usage: ./update_pkgsrc_patches.sh [-d <pkgsrc/chromium/path>]
# Example: ./update_pkgsrc_patches.sh -d /usr/pkgsrc/wip/chromium

# Check arguments
if [ $# -ne 0 ] && [ $# -ne 2 ]; then
        echo "Error: wrong args"
        echo "Usage: ./update_pkgsrc_patches.sh [-d <pkgsrc/chromium/path>]"
        exit 1
fi

for _arg in "$@"; do
    case "$_arg" in
        -d)
            _path="$2"
            shift 2
            ;;
    esac
done

_kaiju_repo=$(pwd)

# Set pkgsrc's chromium path
if [ -n "$_path" ]; then
    if [ ! -d "$_path" ]; then
        echo "Error: $_path is not valid"
        exit 1
    fi
else
    if [ -d /usr/pkgsrc/wip/chromium ]; then
        _path="/usr/pkgsrc/wip/chromium"
    elif [ -d /usr/pkgsrc/www/chromium ]; then
        _path="/usr/pkgsrc/www/chromium"
    else
        echo "Error: can't set pkgsrc's chromium path"
        exit 1
    fi
fi

echo "Used chromium pkgrsc path: $_path"

# Clean pkgsrc chromium/patches
cd "$_path" || exit 1
rm patches/patch-*

# Apply all-in patch in pkgsrc workdir
# Create patches in chromium/patches
# Fix pkglint error: Each patch must be documented
make extract || exit 1
cd work/chromium-* || exit 1
patch -Np1 -i "$_kaiju_repo"/patches/chromium/nb.patch || exit 1
cd "$_path" || exit 1
mkpatches || exit 1
rm patches/*.orig
rm patches/*Cargo.toml
for _patch in patches/patch-*; do
    # shellcheck disable=SC3003
    sed -i'' \
        -e $'3i\\\n* Part of patchset to build on NetBSD\n' \
        -e $'3i\\\n\n' \
        "$_patch" || exit 1
done

# Update pkgsrc's distinfo
# Clean pkgsrc's workdir
make makepatchsum || exit 1
make clean || exit 1

exit 0
