#!/bin/sh

# Usage: ./update_vanila_electron.sh <electron version>
# Example: ./update_vanilla_electron.sh 32.2.7

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
_isend="0"

if [ "$1" != "" ]; then
	e_ver="$1"
else
	echo "Error: not set chromium version"
    echo "Usage: ./update_vanilla.sh <chromium version>"
	exit 1
fi

getver() {
    grep "^$e_ver" electron.versions|cut -d: -f"$1"
}

# get version of sources
_e_main=${e_ver%%.*}
_c_ver=$(getver 2)
_node_ver=$(getver 3)
_nan_ver=$(getver 4)
_sq_ver=$(getver 5)
_ro_ver=$(getver 6)
_m_ver=$(getver 7)
_eng_ver=$(getver 8)
_c_rver=$(getver 9)

c_tarball_url="https://github.com/tagattie/FreeBSD-Electron/releases/download/v${_c_rver}/"

hasrej() {
    _hasrej=0
    _sd=$(pwd)
    _emsg=""
    if [ "$1" ]; then
        cd "$1" || die
    fi
    # shellcheck disable=SC2044
    for _rej in $(find . -type f -name "*.rej"); do
        if [ -e "$_rej" ]; then
            _hasrej=1
            echo "$_rej"
        fi
    done
    cd "$_sd" || die
    if [ "$_hasrej" = "1" ]; then
        if [ "$_isend" = "1" ]; then
       	    _emsg=", after run again script"
	    fi
        echo ">>> Fix rejected patches and git commit them$_emsg"
        return 0
    else
        return 1
    fi
}

# get sources
if [ ! -f "../electron${_e_main}-${e_ver}-download_done" ]; then
    cd .. || die
    for c_num in 0 1 2; do
        curl -L "${c_tarball_url}/chromium-${_c_ver}.tar.xz.${c_num}" -o "chromium-${_c_ver}.tar.xz.${c_num}" || die "curl chromium.${c_num}"
    done
    curl -L "https://github.com/nodejs/node/archive/v${_node_ver}.tar.gz" -o "node-${_node_ver}.tar.gz" || die "curl node"
    curl -L "https://github.com/nodejs/nan/archive/${_nan_ver}.tar.gz" -o "nan-${_nan_ver}.tar.gz" || die "curl nan"
    curl -L "https://github.com/Squirrel/Squirrel.Mac/archive/${_sq_ver}.tar.gz" -o "Squirrel.Mac-${_sq_ver}.tar.gz" || die "curl Squirrel.Mac"
    curl -L "https://github.com/ReactiveCocoa/ReactiveObjC/archive/${_ro_ver}.tar.gz" -o "ReactiveObjC-${_ro_ver}.tar.gz" || die "curl ReactiveObjC"
    curl -L "https://github.com/Mantle/Mantle/archive/${_m_ver}.tar.gz" -o "Mantle-${_m_ver}.tar.gz" || die "curl Mantle"
    curl -L "https://github.com/EngFlow/reclient-configs/archive/${_eng_ver}.tar.gz" -o "reclient-configs-${_eng_ver}.tar.gz" || die "curl reclient-configs"
    curl -L "https://github.com/electron/electron/archive/v${e_ver}.tar.gz" -o "electron-${e_ver}.tar.gz" || die "curl electron"
    cd "$_startdir" || die
    touch "../electron${_e_main}-${e_ver}-download_done"
fi

# extract tarballs
if [ ! -f "../electron${_e_main}-${e_ver}-extract_done" ]; then
    cd .. || die
    mkdir "electron${_e_main}-netbsd-${e_ver}" || die
    cat chromium-"${_c_ver}".tar.xz.? > "chromium-${_c_ver}.tar.xz" || die "cat chromium.?"
    tar -xJf "chromium-${_c_ver}.tar.xz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}" || die "extract chromium"
    sed -i'' 's/swiftshader/swiftshaderXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/vulkan-deps/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/.gitignore"
    mkdir "electron${_e_main}-netbsd-${e_ver}/electron" || die
    tar -xzf "electron-${e_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/electron" || die "extract electron"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/electron_node" || die
    tar -xzf "node-${_node_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/electron_node" || die "extract node"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/nan" || die
    tar -xzf "nan-${_nan_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/nan" || die "extract nan"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac" || die
    tar -xzf "Squirrel.Mac-${_sq_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac" || die "extract squirrel"
    mkdir -p "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/ReactiveObjC" || die
    tar -xzf "ReactiveObjC-${_ro_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/ReactiveObjC" || die "extract ReactiveObjC"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/Mantle" || die
    tar -xzf "Mantle-${_m_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/Mantle" || die "extract mantle"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/engflow-reclient-configs" || die
    tar -xzf "reclient-configs-${_eng_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/engflow-reclient-configs" || die "extract engflow"
    cd "$_startdir" || die
    touch "../electron${_e_main}-${e_ver}-extract_done"
fi

# init git repo
if [ ! -f "../electron${_e_main}-${e_ver}-init_done" ]; then
    cd "../electron${_e_main}-netbsd-${e_ver}" || die
    git init || die
    git add . || die
    git commit -m "Electron-${e_ver}" || die
    cd "$_startdir" || die
    touch "../electron${_e_main}-${e_ver}-init_done"
fi

# Apply electron shipped patchset
if [ ! -f "../electron${_e_main}-${e_ver}-electronpatches_done" ]; then
    cd "../electron${_e_main}-netbsd-${e_ver}" || die
    _bd=$(pwd)

    for _dirs in $(sed -n 's|.*patch_dir": "src\(.*\)", "repo": "src\(.*\)".*|.\1:.\2|p' < "$_bd"/electron/patches/config.json); do
        _patchdir=$(echo "$_dirs" | cut -d: -f1)
        _srcdir=$(echo "$_dirs" | cut -d: -f2)
        cd "$_bd"/"$_srcdir" || die
        for _patch in "$_bd/$_patchdir"/*; do
            git apply --reject --directory="$(git rev-parse --show-prefix)" "${_patch}"
        done
    done

    cd "$_bd" || die
    if hasrej >/dev/null; then 
        find . -type f -name "*.rej" -exec mv -t ../ {} +
        _broken=1
    fi
    git add . || die
    git commit -m "Apply Electron patchset" || die

    if [ "$_broken" = "1" ] && [ -e "../kaiju/patches/electron${_e_main}/nb-efix.patch" ]; then
        git apply --reject "../kaiju/patches/electron${_e_main}/nb-efix.patch"
        _broken=0
    fi
    cd "$_startdir" || die
    touch "../electron${_e_main}-${e_ver}-electronpatches_done"
    if [ "$_broken" = "1" ]; then
        echo "Error to fix rejected patches:"
        find ../ -type f -name "*.rej"
        exit 1
    fi
    hasrej "$_bd" && exit 1
fi

# Apply freebsd patchset in wip branch
if [ ! -f "../electron${_e_main}-${e_ver}-fbpatches_done" ]; then
    # First commit the official electron patches
    git add . || die
    git commit -m "Apply Electron fix patchset" || die

    if [ -d "../freebsd-ports/devel/electron${_e_main}/files" ]; then
        p_dir="../freebsd-ports/devel/electron${_e_main}/files"
    else
        echo "Error: not found freebsd ports tree"
        exit 1
    fi

    cd "${p_dir}/../../.." || die
    git pull || die "FreeBSD-ports update: "

    cd "../electron${_e_main}-netbsd-${e_ver}" || die
    for _patch in "$p_dir"/patch-*; do
        if [ -e "$_patch" ]; then
            patch -Np0 -i "$_patch"
        fi
    done

    git add . || die
    git commit -m "Apply FreeBSD patchset" || die
    cd "$_startdir" || die
    touch "../electron${_e_main}-${e_ver}-fbpatches_done"
    hasrej "../electron${_e_main}-netbsd-${e_ver}" && exit 1
fi

# Apply NetBSD delta patch
cd "../electron${_e_main}-netbsd-${e_ver}" || die
if [ -e "../kaiju/patches/electron${_e_main}/nb-delta.patch" ]; then
    _isend="1"
    # clean distfiles, status files
    rm "../chromium-${_c_ver}.tar.xz"* || die
    rm "../node-${_node_ver}.tar.gz" || die
    rm "../nan-${_nan_ver}.tar.gz" || die
    rm "../Squirrel.Mac-${_sq_ver}.tar.gz" || die
    rm "../ReactiveObjC-${_ro_ver}.tar.gz" || die
    rm "../Mantle-${_m_ver}.tar.gz" || die
    rm "../reclient-configs-${_eng_ver}.tar.gz" || die
    rm "../electron-${e_ver}.tar.gz" || die
    rm "../electron${_e_main}-${e_ver}-download_done"
    rm "../electron${_e_main}-${e_ver}-extract_done"
    rm "../electron${_e_main}-${e_ver}-init_done"
    rm "../electron${_e_main}-${e_ver}-electronpatches_done"
    rm "../electron${_e_main}-${e_ver}-fbpatches_done"

    git apply --reject "../kaiju/patches/electron${_e_main}/nb-delta.patch"
    hasrej && exit 1
fi

exit 0
