#!/usr/bin/env bash
# tools/install_native_compressors.sh — best-effort installer for the
# native compressors that LLCBench depends on.  Designed for Ubuntu/Debian
# and macOS (Homebrew). For other platforms you'll need to install the
# binaries manually; please consult docs/algorithms.md.

set -euo pipefail
SUDO=${SUDO:-sudo}

if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null; then
        echo "Please install Homebrew first: https://brew.sh"
        exit 1
    fi
    brew install bzip2 pbzip2 lzop liblzo2 pigz brotli zstd p7zip lz4 lizard
    brew tap brewsci/bio || true
    brew install bsc      || true        # optional
    brew install zpaq     || true
    brew install snzip    || true
    exit 0
fi

# ---- Linux (Debian/Ubuntu) ----
${SUDO} apt-get update
${SUDO} apt-get install -y \
    build-essential cmake git pkg-config \
    bzip2 pbzip2 lzop liblzo2-bin liblzo2-dev pigz brotli zstd p7zip-full lz4

WORKDIR="${WORKDIR:-$(mktemp -d)}"
cd "${WORKDIR}"

# ---- Lizard ----
git clone --depth=1 https://github.com/inikep/lizard
make -C lizard -j"$(nproc)"
${SUDO} cp lizard/lizard /usr/local/bin/

# ---- BSC ----
git clone --depth=1 https://github.com/IlyaGrebnov/libbsc
make -C libbsc -j"$(nproc)"
${SUDO} cp libbsc/bsc /usr/local/bin/

# ---- ZPAQ ----
git clone --depth=1 https://github.com/zpaq/zpaq.git
make -C zpaq -j"$(nproc)"
${SUDO} cp zpaq/zpaq /usr/local/bin/

# ---- SnZip ----
git clone --depth=1 https://github.com/kubo/snzip
( cd snzip && ./autogen.sh && ./configure && make -j"$(nproc)" && ${SUDO} make install )

# ---- SPDP ----
git clone --depth=1 https://github.com/luiztauffer/SPDP || \
    git clone --depth=1 https://github.com/burtscher/SPDPcompressor || true
if [[ -d SPDPcompressor ]]; then
    make -C SPDPcompressor || true
    ${SUDO} cp SPDPcompressor/spdp /usr/local/bin/ || true
fi

# ---- FPZip (CLI binary) ----
git clone --depth=1 https://github.com/llnl/fpzip
( cd fpzip && cmake -B build -DBUILD_TESTING=OFF && cmake --build build --target fpzip-cli || true )

echo
echo "Native compressors installed (or skipped if unavailable). Verify with:"
for bin in 7zz lzop bzip2 pbzip2 lizard bsc brotli pigz zstd snzip zpaq; do
    if command -v "${bin}" >/dev/null; then
        printf "  ✔  %-8s -> %s\n" "${bin}" "$(command -v "${bin}")"
    else
        printf "  ✗  %-8s missing\n" "${bin}"
    fi
done
