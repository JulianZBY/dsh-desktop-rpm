#!/bin/bash
# Copr custom source method: builds an SRPM of the latest upstream release.
# https://copr.fedorainfracloud.org/coprs/ -> package -> source method: custom
set -euxo pipefail

SPEC_RAW="https://raw.githubusercontent.com/JulianZBY/dsh-desktop-rpm/main"
UPSTREAM="https://github.com/anywhere-labs/dsh-desktop"

dnf -y -q install rpm-build curl

VER=$(curl -sSfL -o /dev/null -w '%{url_effective}' "${UPSTREAM}/releases/latest" | sed -E 's|.*/tag/v||')
case "$VER" in
    ''|*[!0-9.]*) echo "ERROR: bad version resolved: $VER" >&2; exit 1 ;;
esac

TGZ="DSH-Desktop-${VER}-linux-x64.tar.gz"
curl -sSfL -o "$TGZ" "${UPSTREAM}/releases/download/v${VER}/${TGZ}"

curl -sSfLO "${SPEC_RAW}/dsh-desktop.spec"
curl -sSfLO "${SPEC_RAW}/dsh-desktop-icon.png"
curl -sSfLO "${SPEC_RAW}/dsh.desktop"

sed -i -E "s/^(Version:[[:space:]]+).*/\\1${VER}/" dsh-desktop.spec

rpmbuild -bs --define "_sourcedir ${PWD}" --define "_srcrpmdir ${PWD}" dsh-desktop.spec
cp -v ./*.src.rpm "${COPR_RESULTDIR:-${PWD}}/"
