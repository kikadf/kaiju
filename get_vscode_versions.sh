#!/bin/sh

# Usage: ./get_vscode_versions.sh
# Example: ./get_vscode_versions.sh

_startdir=$PWD

. "$_startdir/kaiju.conf"
. "$_startdir/include/kaiju.sh"

cd "$tools_workdir" || die
fetch_freebsd_ports

# get version of sources
_v_ver=$(get_value VSCODE_VERSION vscode)
_sc_ver=$(get_value SOURCE_COMMIT_HASH vscode)
_rs_ver=$(get_value RSPACK_VERSION vscode)
_ccli_ver=$(get_value COPILOT_CLI_VERSION vscode)
_csdk_ver=$(get_value COPILOT_SDK_VERSION vscode)
_pr_ver=$(get_value OS_PROXY_RESOLVER_VERSION vscode)

_versions="$_v_ver:$_sc_ver:$_rs_ver:$_ccli_ver:$_csdk_ver:$_pr_ver"

grep -q "$_versions" "$_startdir/vscode.versions" \
    || echo "$_versions" >> "$_startdir/vscode.versions"

exit 0
