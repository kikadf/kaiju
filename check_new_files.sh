#!/bin/sh

# Usage: ./check_new_files.sh <chromium version>
# Example: ./check_new_files.sh 120.6099.216

find_chromium_dirs() {
    find  ../ -maxdepth 1 -type d -name "chromium-netbsd-*" \
        | cut -d'-' -f3 \
        | sort -t. -n -r -k1,1 -k2,2 -k3,3 -k4,4
}

find_prev_chromium_dir() {
    unset _m
    for i in $(find_chromium_dirs); do
        if [ "$_m" = "1" ]; then
            echo "$i"
            break
        fi
        if [ "$i" = "$1" ]; then 
            _m=1
        fi
    done
    if [ "$_m" != "1" ]; then
        echo ">>> Error: not found chromium-netbsd-* directories in $(pwd)/.. path"
        exit 1
    fi
}

_curr_chromium_dir="../chromium-netbsd-$1"
_prev_chromium_dir="../chromium-netbsd-$(find_prev_chromium_dir "$1")"
_checked_files="\
        base/process/process_handle_openbsd.cc \
        base/process/process_iterator_openbsd.cc \
        base/process/process_metrics_openbsd.cc \
        base/process/process_handle_freebsd.cc \
        base/process/process_iterator_freebsd.cc \
        base/process/process_metrics_freebsd.cc \
        base/system/sys_info_openbsd.cc \
        build/toolchain/openbsd/BUILD.gn \
        sandbox/policy/openbsd/sandbox_openbsd.cc \
        sandbox/policy/openbsd/sandbox_openbsd.h \
        services/device/hid/hid_connection_freebsd.cc \
        services/device/hid/hid_connection_freebsd.h \
        services/device/hid/hid_service_freebsd.cc \
        services/device/hid/hid_service_freebsd.h \
        services/device/hid/hid_connection_fido.cc \
        services/device/hid/hid_connection_fido.h \
        services/device/hid/hid_service_fido.cc \
        services/device/hid/hid_service_fido.h \
        media/audio/sndio \
        "

for _file in $_checked_files; do
    echo ">>> Check $_file:"
    diff -Naur "$_prev_chromium_dir/$_file" "$_curr_chromium_dir/$_file"
done

exit 0