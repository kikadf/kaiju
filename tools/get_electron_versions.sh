#!/bin/sh

# Usage: ./get_electron_versions.sh <electron-port>
# Example: ./get_electron_versions.sh "electron34"

_startdir=$(pwd)

. "$_startdir/kaiju.conf"
. "$_startdir/../include/kaiju.sh"

if [ "$1" != "" ]; then
	ename="$1"
else
	echo "Error: not set url of electron port"
    echo "Usage: ./get_electron_versions.sh <electron-port>"
	exit 1
fi

cd "$tools_workdir" || die
fetch_freebsd_ports

# get version of sources
_e_ver=$(get_value ELECTRON_VER "$ename")
_c_ver=$(get_value CHROMIUM_VER "$ename")
_node_ver=$(get_value NODE_VER "$ename")
_nan_ver=$(get_value NAN_VER "$ename")
_sq_ver=$(get_value SQUIRREL_MAC_VER "$ename")
_ro_ver=$(get_value REACTIVEOBJC_VER "$ename")
_m_ver=$(get_value MANTLE_VER "$ename")
_eng_ver=$(get_value ENGFLOW_RECLIENT_CONFIGS_VER "$ename")
_c_rver=$(get_urlsf_chr "$ename")

_versions="$_e_ver:$_c_ver:$_node_ver:$_nan_ver:$_sq_ver:$_ro_ver:$_m_ver:$_eng_ver:$_c_rver"

grep -q "$_versions" "$_startdir/electron.versions" \
    || echo "$_versions" >> "$_startdir/electron.versions"

exit 0