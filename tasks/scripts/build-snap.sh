#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPRESSED_DIR="${ROOT}/target/vm-runtime-compressed"

runtime_artifacts=()
case "$(uname -m)" in
    x86_64|amd64)
        runtime_artifacts=(libkrun.so.zst libkrunfw.so.5.zst gvproxy.zst)
        ;;
    aarch64|arm64)
        runtime_artifacts=(libkrun.so.zst libkrunfw.so.5.zst gvproxy.zst)
        ;;
    *)
        echo "Error: unsupported architecture for snap build: $(uname -m)" >&2
        exit 1
        ;;
esac

missing_runtime=0
for artifact in "${runtime_artifacts[@]}"; do
    if [ ! -f "${COMPRESSED_DIR}/${artifact}" ]; then
        missing_runtime=1
        break
    fi
done

if [ "$missing_runtime" -eq 1 ]; then
    echo "==> Preparing VM runtime artifacts..."
    "${ROOT}/tasks/scripts/vm/vm-setup.sh"
fi

if [ ! -f "${COMPRESSED_DIR}/rootfs.tar.zst" ]; then
    echo "==> Building base VM rootfs tarball..."
    "${ROOT}/tasks/scripts/vm/build-rootfs-tarball.sh" --base
fi

echo "==> Building OpenShell Core ROCK (Gateway + Supervisor)..."
rm -f openshell-core_*_*.rock
cd "${ROOT}"
rockcraft pack

echo "==> Exporting ROCK to snap/local-images..."
mkdir -p snap/local-images
cp openshell-core*.rock snap/local-images/openshell-core.rock

echo "==> Building Snap package..."
rm -f openshell_*_*.snap
# If arguments are passed (like --build-for), forward them to snapcraft
if [ $# -eq 0 ]; then
    snapcraft pack
else
    snapcraft pack "$@"
fi
