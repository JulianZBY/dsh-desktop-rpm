#!/bin/bash
# Copr custom source method: builds an SRPM of the latest upstream NEXT-channel release.
set -euxo pipefail

SPEC_RAW="https://raw.githubusercontent.com/JulianZBY/dsh-desktop-rpm/main"
UPSTREAM="https://github.com/anywhere-labs/dsh-desktop"

TAG=$(curl -sSfL "https://api.github.com/repos/anywhere-labs/dsh-desktop/releases?per_page=30" \
    | grep -m1 -oE '"tag_name": *"v[0-9.]+-next"' | grep -oE 'v[0-9.]+-next')
VER=${TAG#v}
case "$VER" in
    *[!0-9.]*|'') echo "ERROR: bad next version resolved: ${VER:-empty}" >&2; exit 1 ;;
esac

TGZ="DSH-NEXT-${VER}-linux-x64.tar.gz"
curl -sSfL -o "$TGZ" "${UPSTREAM}/releases/download/v${VER}/${TGZ}"

curl -sSfLO "${SPEC_RAW}/dsh-desktop.spec"
curl -sSfLO "${SPEC_RAW}/SOURCES/dsh-desktop-icon.png"
curl -sSfLO "${SPEC_RAW}/dsh.desktop"

sed -i -E "s/^(%global upstream_ver ).*/\\1${VER}/" dsh-desktop.spec
sed -i -E "s/^(Version:[[:space:]]+).*/\\1${VER/-/~}/" dsh-desktop.spec

rpmbuild -bs --define "_sourcedir ${PWD}" --define "_srcrpmdir ${PWD}" dsh-desktop.spec
RESULT="${COPR_RESULTDIR:-${PWD}}"
if [[ "${RESULT%/}" != "${PWD}" ]]; then cp -v ./*.src.rpm "${RESULT%/}/"; fi
