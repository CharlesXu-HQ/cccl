#!/usr/bin/env bash

# Installs the cuda-compat package and configures ldconfig so the compat
# driver libraries are preferred over the host driver.
#
# This setup is shared between both devcontainer launch paths:
#  - VS Code launches invoke this script via postStartCommand.
#  - Docker launches invoke this script from cccl-entrypoint.sh.

set -euo pipefail

# Only install in containers using the latest CUDA toolkit.
if [[ "${CCCL_CUDA_LATEST:-false}" != "true" ]]; then
    exit 0
fi

# WSL hosts pass the Windows driver through to containers, so the compat
# libraries are unnecessary there and are not installed.
if grep -qi microsoft /proc/version; then
    echo "WSL host detected, skipping cuda-compat installation."
    exit 0
fi

if [[ -z "${CCCL_CUDA_VERSION:-}" ]]; then
    echo "CCCL_CUDA_VERSION is not set, cannot install cuda-compat." >&2
    exit 1
fi

sudo apt-get update
sudo apt-get install -y "cuda-compat-${CCCL_CUDA_VERSION/./-}"

# Point the dynamic linker at the compat libraries so they take precedence
# over the host driver.
compat_dir="/usr/local/cuda/compat"
if [[ ! -d "${compat_dir}" ]]; then
    echo "cuda-compat installed, but ${compat_dir} does not exist." >&2
    exit 1
fi
echo "${compat_dir}" | sudo tee /etc/ld.so.conf.d/cuda-compat.conf >/dev/null
sudo ldconfig

echo "cuda-compat-${CCCL_CUDA_VERSION/./-} installed and configured."
