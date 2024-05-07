#!/bin/sh

# Usage: ./update_vanila.sh <chromium version>
# Example: ./update_vanilla.sh 120.006099.216

c_tarball_url="https://commondatastorage.googleapis.com/chromium-browser-official"

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
    echo "Usage: ./update_vanilla.sh <chromium version>"
	exit 1
fi

# get chromium
curl "${c_tarball_url}/chromium-${c_ver}.tar.xz" -o "../chromium-${c_ver}.tar.xz" || die "curl chromium"
curl "${c_tarball_url}/chromium-${c_ver}.tar.xz.hashes" -o "../chromium-${c_ver}.tar.xz.hashes" || die "curl hashes"
cd .. || die
sed -n 's|sha256 *\(.*\)|\1|p' "chromium-${c_ver}.tar.xz.hashes" | sha256sum -c || die checksum

# extract tarball
mkdir "chromium-netbsd-${c_ver}" || die
tar -xJf "chromium-${c_ver}.tar.xz" --strip-components=1 -C "chromium-netbsd-${c_ver}" || die extract
sed 's/swiftshader/swiftshaderXXX/g' -i "chromium-netbsd-${c_ver}/third_party/.gitignore"
sed 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' -i "chromium-netbsd-${c_ver}/third_party/vulkan-deps/.gitignore"

# init git repo
cd "chromium-netbsd-${c_ver}" || die
git init || die
git add . || die
git commit -m "Chromium-${c_ver}" || die

# clean distfiles
rm "../chromium-${c_ver}.tar.xz" || die
rm "../chromium-${c_ver}.tar.xz.hashes" || die

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
        patch -Np0 -i "$_patch" || die "Apply OpenBSD patches"
    fi
done

git add . || die
git commit -m "Apply OpenBSD patchset" || die

# Apply NetBSD delta patch
if [ -e "../kaiju/patches/chromium/nb-delta.patch" ]; then
    git apply --reject ../kaiju/patches/chromium/nb-delta.patch || die "Apply NetBSD delta patch"
fi

exit 0
