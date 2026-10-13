#!/bin/sh

# Usage: ./update_vanila_electron.sh <electron version>
# Example: ./update_vanilla_electron.sh 32.2.7

_startdir=$PWD

. "$_startdir/kaiju.conf"
. "$_startdir/include/kaiju.sh"

if [ "$1" != "" ]; then
    e_ver="$1"
else
    echo "Error: not set electron version"
    echo "Usage: ./update_vanilla_electron.sh <electron version>"
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
_rollup_ver=$(getver 9)

_epatch_rej="${_startdir}/patches/electron${_e_main}/epatch_rej"

# create workdir
mkdir -p "$tools_workdir" || die

# get sources
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-download_done" ]; then
    cd "$tools_workdir" || die
    echo "Download distfiles..."
    if [ ! -f "$distfiles/chromium-${_c_ver}-pkgsrc.tar.xz" ]; then
         curl -L "https://github.com/kikadf/chromium-tarballs/releases/download/${_c_ver}/chromium-${_c_ver}-pkgsrc.tar.xz" \
              -o "$distfiles/chromium-${_c_ver}-pkgsrc.tar.xz" \
              || die "curl chromium"
    fi
    if [ ! -f "$distfiles/nodejs-node-v${_node_ver}.tar.gz" ]; then
         curl -L "https://github.com/nodejs/node/archive/v${_node_ver}.tar.gz" \
              -o "$distfiles/nodejs-node-v${_node_ver}.tar.gz" \
              || die "curl node"
    fi
    if [ ! -f "$distfiles/nodejs-nan-${_nan_ver}.tar.gz" ]; then
         curl -L "https://github.com/nodejs/nan/archive/${_nan_ver}.tar.gz" \
              -o "$distfiles/nodejs-nan-${_nan_ver}.tar.gz" \
              || die "curl nan"
    fi
    if [ ! -f "$distfiles/Squirrel-Squirrel.Mac-${_sq_ver}.tar.gz" ]; then
         curl -L "https://github.com/Squirrel/Squirrel.Mac/archive/${_sq_ver}.tar.gz" \
              -o "$distfiles/Squirrel-Squirrel.Mac-${_sq_ver}.tar.gz" \
              || die "curl Squirrel.Mac"
    fi
    if [ ! -f "$distfiles/ReactiveCocoa-ReactiveObjC-${_ro_ver}.tar.gz" ]; then
         curl -L "https://github.com/ReactiveCocoa/ReactiveObjC/archive/${_ro_ver}.tar.gz" \
              -o "$distfiles/ReactiveCocoa-ReactiveObjC-${_ro_ver}.tar.gz" \
              || die "curl ReactiveObjC"
    fi
    if [ ! -f "$distfiles/Mantle-Mantle-${_m_ver}.tar.gz" ]; then
         curl -L "https://github.com/Mantle/Mantle/archive/${_m_ver}.tar.gz" \
              -o "$distfiles/Mantle-Mantle-${_m_ver}.tar.gz" \
              || die "curl Mantle"
    fi
    if [ ! -f "$distfiles/EngFlow-reclient-configs-${_eng_ver}.tar.gz" ]; then
         curl -L "https://github.com/EngFlow/reclient-configs/archive/${_eng_ver}.tar.gz" \
              -o "$distfiles/EngFlow-reclient-configs-${_eng_ver}.tar.gz" \
              || die "curl reclient-configs"
    fi
    if [ ! -f "$distfiles/electron${_e_main}-${e_ver}.tar.gz" ]; then
         curl -L "https://github.com/electron/electron/archive/v${e_ver}.tar.gz" \
              -o "$distfiles/electron${_e_main}-${e_ver}.tar.gz" \
              || die "curl electron"
    fi
    if [ ! -f "$distfiles/rollup-rollup-v${_rollup_ver}.tar.gz" ]; then
        curl -L "https://github.com/rollup/rollup/archive/v${_rollup_ver}.tar.gz" \
             -o "$distfiles/rollup-rollup-v${_rollup_ver}.tar.gz" \
             || die "curl rollup"
    fi
    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-download_done"
fi

# extract tarballs
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-extract_done" ]; then
    cd "$tools_workdir" || die
    echo "Extract distfiles to electron${_e_main}-netbsd-${e_ver}..."
    mkdir -p "electron${_e_main}-netbsd-${e_ver}" || die
    tar -xJf "$distfiles/chromium-${_c_ver}-pkgsrc.tar.xz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}" || die "extract chromium"
    mkdir "electron${_e_main}-netbsd-${e_ver}/electron" || die
    tar -xzf "$distfiles/electron${_e_main}-${e_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/electron" || die "extract electron"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/electron_node" || die
    tar -xzf "$distfiles/nodejs-node-v${_node_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/electron_node" || die "extract node"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/nan" || die
    tar -xzf "$distfiles/nodejs-nan-${_nan_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/nan" || die "extract nan"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac" || die
    tar -xzf "$distfiles/Squirrel-Squirrel.Mac-${_sq_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac" || die "extract squirrel"
    mkdir -p "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/ReactiveObjC" || die
    tar -xzf "$distfiles/ReactiveCocoa-ReactiveObjC-${_ro_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/ReactiveObjC" || die "extract ReactiveObjC"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/Mantle" || die
    tar -xzf "$distfiles/Mantle-Mantle-${_m_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/vendor/Mantle" || die "extract mantle"
    mkdir "electron${_e_main}-netbsd-${e_ver}/third_party/engflow-reclient-configs" || die
    tar -xzf "$distfiles/EngFlow-reclient-configs-${_eng_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/third_party/engflow-reclient-configs" || die "extract engflow"
    mkdir "electron${_e_main}-netbsd-${e_ver}/rollup" || die
    tar -xzf "$distfiles/rollup-rollup-v${_rollup_ver}.tar.gz" --strip-components=1 -C "electron${_e_main}-netbsd-${e_ver}/rollup" || die "extract rollup"

    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-extract_done"
fi

# get node modules
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-node_done" ]; then
    cd "$tools_workdir/electron${_e_main}-netbsd-${e_ver}/electron"
    HOME="$PWD" XDG_CACHE_HOME="$PWD/.ecache" \
    YARN_GLOBAL_FOLDER="$PWD/.ecache/yarn-global" \
    YARN_CACHE_FOLDER="$PWD/.ecache/electron${_e_main}-node_modules-${_ver}" \
    YARN_ENABLE_GLOBAL_CACHE=false \
    YARN_ENABLE_TELEMETRY=0 \
    YARN_ENABLE_SCRIPTS=false \
    yarn install --immutable --mode=skip-build
    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-node_done"
fi

# init git repo
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-init_done" ]; then
    cd "$tools_workdir"
    echo "*.rej" >> "electron${_e_main}-netbsd-${e_ver}/.gitignore"
    echo "*.rej.*" >> "electron${_e_main}-netbsd-${e_ver}/.gitignore"
    echo "*.orig" >> "electron${_e_main}-netbsd-${e_ver}/.gitignore"
    echo "*.gitignore" >> "electron${_e_main}-netbsd-${e_ver}/.gitignore"
    echo "/electron/.ecache" >> "electron${_e_main}-netbsd-${e_ver}/.gitignore"
    sed -i'' 's/swiftshader/swiftshaderXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/vulkan-deps/.gitignore"
    sed -i'' 's/vulkan-validation-layers/vulkan-validation-layersXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-loader/vulkan-loadersXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/.gitignore"
    sed -i'' 's/vulkan-loader/vulkan-loadersXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/vulkan-deps/.gitignore"
    sed -i'' 's/dawn_commit_hash/dawn_commit_hashXXX/g' "electron${_e_main}-netbsd-${e_ver}/gpu/webgpu/.gitignore"
    sed -i'' 's/third_party\/\*/third_partyXXX\/\*/g' "electron${_e_main}-netbsd-${e_ver}/third_party/devtools-frontend/src/.gitignore"
    sed -i'' 's/node_modules/node_modulesXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/electron_node/.gitignore"
    sed -i'' 's/node_modules/node_modulesXXX/g' "electron${_e_main}-netbsd-${e_ver}/electron/.gitignore"
    sed -i'' 's/engflow-reclient-configs/engflow-reclient-configsXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/.gitignore"
    sed -i'' 's/vendor/vendorXXX/g' "electron${_e_main}-netbsd-${e_ver}/third_party/squirrel.mac/.gitignore"
    sed -i'' 's/nacl/naclXXX/g' "electron${_e_main}-netbsd-${e_ver}/buildtools/reclient_cfgs/.gitignore"

    cd "$tools_workdir/electron${_e_main}-netbsd-${e_ver}"
    git init || die
    git add . || die
    git commit -m  "Electron-${e_ver}" || die
    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-init_done"
fi

# Apply electron shipped patchset
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-electronpatches_done" ]; then
    cd "$tools_workdir/electron${_e_main}-netbsd-${e_ver}" || die
    _bd=$PWD
    n=0

    for _dirs in $(sed -n 's|.*patch_dir": "src\(.*\)", "repo": "src\(.*\)".*|.\1:.\2|p' < "$_bd"/electron/patches/config.json); do
        _patchdir=$(echo "$_dirs" | cut -d: -f1)
        _srcdir=$(echo "$_dirs" | cut -d: -f2)
        cd "$_bd"/"$_srcdir" || die
        while read -r _patch; do
            n=$((n + 1))
            git apply --reject --directory="$(git rev-parse --show-prefix)" "${_bd}/${_patchdir}/${_patch}" \
                || find . -type f -name '*.rej' -exec mv '{}' '{}.'"$n" \;
        done < "${_bd}/${_patchdir}/.patches"
    done

    cd "$_bd" || die
    sed -i'' 's/electron/electronXXX/g' ".gitignore"
    sed -i'' 's/electron_node/electron_nodeXXX/g' "third_party/.gitignore"
    sed -i'' 's/squirrel.mac/squirrel.macXXX/g' "third_party/.gitignore"
    sed -i'' 's/nan/nanXXX/g' "third_party/.gitignore"

    git add .
    git commit -m "Apply Electron patchset"

    # Save rejected filelist
    find . -type f -name '*.rej*' -exec md5 {} + > "${_epatch_rej}_new.txt"
    find . -type f -name '*.rej*' -exec md5 {} + |cut -d= -f2 > "${_epatch_rej}_new.hash"

    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-electronpatches_done"
fi

# Fix electron patches
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-fixelectronpatches_done" ]; then
    cd "$tools_workdir/electron${_e_main}-netbsd-${e_ver}" || die

    if find . -type f -name "*.rej*" -exit 1; then
        mv "${_epatch_rej}_new.hash" "${_epatch_rej}_last.hash"
        mv "${_epatch_rej}_new.txt" "${_epatch_rej}_last.txt"
        git add .
        git commit -m "Fix electron patchset"
    else
        if [ -f "${_epatch_rej}_last.hash" ]; then
            echo ":::::::::: Changes in the rejected patches ::::::::::::::"
            diff -Naur "${_epatch_rej}_last.hash" "${_epatch_rej}_new.hash"
            echo ":::::::::: Changes in the rejected patches ::::::::::::::"
        else
            echo "::: Not found ${_epatch_rej}_last.hash to diff the changes"
        fi
        echo "ERROR: electron shipped patches failed again:"
        find . -type f -name "*.rej*"
        echo "Fix with:"
        echo "\$ cd $tools_workdir/electron${_e_main}-netbsd-${e_ver}"
        echo "\$ git apply --reject ${_startdir}/patches/electron${_e_main}/nb-efix.patch"
        echo "And check manually the rejected patches"
        echo "If all fixed, don't forget to remove *.rej files and run:"
        echo "\$ cd ${_startdir}"
        echo "\$ ./update_vanilla_electron.sh ${e_ver}"
        exit 1
    fi

    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-fixelectronpatches_done"
fi

# Apply FreeBSD patchset
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-fbpatches_done" ]; then
    cd "$tools_workdir" || die
    fetch_freebsd_ports
    if [ -d "freebsd-ports/devel/electron${_e_main}/files" ]; then
        p_dir="../freebsd-ports/devel/electron${_e_main}/files"
    else
        echo "Error: not found freebsd ports tree"
        exit 1
    fi

    cd "electron${_e_main}-netbsd-${e_ver}" || die
    for _patch in "$p_dir"/patch-electron* \
                  "$p_dir"/patch-rollup* \
                  "$p_dir"/patch-third__party_electron__node* ; do
        if [ -e "$_patch" ]; then
            patch -Np0 -i "$_patch"
        fi
    done

    git add . || die
    git commit -m "Apply FreeBSD patchset" || die
    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-fbpatches_done"
fi

# Fix FreeBSD patches
if [ ! -f "$tools_workdir/electron${_e_main}-${e_ver}-fixfbpatches_done" ]; then
    cd "$tools_workdir/electron${_e_main}-netbsd-${e_ver}" || die

    if find . -type f -name "*.rej" -exit 1; then
        git add .
        git commit -m "Fix FreeBSD patchset"
    else
        echo "ERROR: FreeBSD patches failed:"
        find . -type f -name "*.rej"
        echo "Fix manually and run:"
        echo "\$ cd ../.."
        echo "\$ ./update_vanilla_electron.sh ${e_ver}"
        exit 1
    fi

    cd "$_startdir" || die
    touch "$tools_workdir/electron${_e_main}-${e_ver}-fixfbpatches_done"
fi

# Apply NetBSD delta patch
cd "$tools_workdir/electron${_e_main}-netbsd-${e_ver}" || die
# clean status files
rm "../electron${_e_main}-${e_ver}"*_done
if [ -e "${_startdir}/patches/electron${_e_main}/nb-delta.patch" ]; then
    git apply --reject "${_startdir}/patches/electron${_e_main}/nb-delta.patch" || die "Apply NetBSD delta patch"
    echo "Finished. Don't forget to commit NetBSD patchset."
else
    echo "Abort: ${_startdir}/patches/electron${_e_main}/nb-delta.patch not found"
    exit 1
fi

exit 0
