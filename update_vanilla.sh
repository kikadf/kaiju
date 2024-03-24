#!/bin/sh

# Usage: ./update_vanila.sh <chromium version>
# Example: ./update_vanilla.sh 120.006099.216

c_tarball_url="https://commondatastorage.googleapis.com/chromium-browser-official"

if [ "$1" != "" ]; then
	c_ver="$1"
else
	echo "Error: not set chromium version"
    echo "Usage: ./update_vanilla.sh <chromium version>"
	exit 1
fi

# get chromium
curl "${c_tarball_url}/chromium-${c_ver}.tar.xz" -o "../chromium-${c_ver}.tar.xz" || exit 1
curl "${c_tarball_url}/chromium-${c_ver}.tar.xz.hashes" -o "../chromium-${c_ver}.tar.xz.hashes" || exit 1
cd .. || exit 1
sed -n 's|sha256 *\(.*\)|\1|p' "chromium-${c_ver}.tar.xz.hashes" | sha256sum -c || exit 1

# extract tarball
mkdir "chromium-netbsd-${c_ver}" || exit 1
tar -xJf "chromium-${c_ver}.tar.xz" --strip-components=1 -C "chromium-netbsd-${c_ver}" || exit 1

# init git repo
cd "chromium-netbsd-${c_ver}" || exit 1
git init || exit 1
git add . || exit 1
git commit -m "Chromium-${c_ver}" || exit 1

# clean distfiles
rm "../chromium-${c_ver}.tar.xz" || exit 1
rm "../chromium-${c_ver}.tar.xz.hashes" || exit 1

# Apply openbsd patchset in wip branch
if [ -d "../openbsd-ports/www/chromium/patches" ]; then
    p_dir="../openbsd-ports/www/chromium/patches"
elif [ -d "../ports/www/chromium/patches" ]; then
    p_dir="../ports/www/chromium/patches"
else
    echo "Error: not found openbsd ports tree"
    exit 1
fi

for _patch in "$p_dir"/patch-*; do
    if [ -e "$_patch" ]; then
        patch -Np0 -i "$_patch" || exit 1
    fi
done

git add . || exit 1
git commit -m "Apply OpenBSD patchset" || exit 1

# Apply NetBSD delta patch
if [ -e "../kaiju/patches/chromium/nb-delta.patch" ]; then
    git apply --reject ../kaiju/patches/chromium/nb-delta.patch || exit 1
fi

exit 0
