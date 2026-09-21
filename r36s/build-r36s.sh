#!/usr/bin/env bash
set -euo pipefail

# PokéRecomp R36S/RK3326 build
# This uses the same Godot 4.8-dev4 commit and custom stripped export-template
# build used by upstream CI, but produces a dedicated R36S preset/package.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT_VERSION="4.8-dev4"
GODOT_TEMPLATE_DIR="4.8.dev4"
GODOT_COMMIT="b56a91878e7c94977e4af978968e41d0670c0a8b"
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}"

mkdir -p .r36s-toolchain .r36s-build dist

# Prefer an existing Godot executable.
if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
else
    # This script is intended to run on an ARM64 Linux build host.
    # The official 4.8-dev4 ARM64 editor is used for the export command.
    if [ ! -x .r36s-toolchain/Godot ]; then
        tmp=".r36s-toolchain/godot.zip"
        curl -fL "$BASE_URL/Godot_v${GODOT_VERSION}_linux.arm64.zip" -o "$tmp"
        rm -rf .r36s-toolchain/editor
        mkdir -p .r36s-toolchain/editor
        unzip -q "$tmp" -d .r36s-toolchain/editor
        found="$(find .r36s-toolchain/editor -type f -name 'Godot_v*_linux.arm64' -print -quit)"
        test -n "$found"
        cp "$found" .r36s-toolchain/Godot
        chmod +x .r36s-toolchain/Godot
    fi
    GODOT_BIN="$ROOT/.r36s-toolchain/Godot"
fi

# Build the project-specific stripped ARM64 export template from the exact
# Godot commit pinned by upstream PokéRecomp CI.
if [ ! -f .r36s-toolchain/templates/linux_release.arm64 ]; then
    command -v git >/dev/null
    command -v scons >/dev/null || {
        echo "ERROR: scons is required to build the ARM64 export template." >&2
        exit 2
    }

    rm -rf .r36s-toolchain/godot-src
    git init -q .r36s-toolchain/godot-src
    git -C .r36s-toolchain/godot-src remote add origin https://github.com/godotengine/godot.git
    git -C .r36s-toolchain/godot-src fetch -q --depth 1 origin "$GODOT_COMMIT"
    git -C .r36s-toolchain/godot-src checkout -q FETCH_HEAD

    rm -rf .r36s-toolchain/templates
    mkdir -p .r36s-toolchain/templates
    SCONSFLAGS="-j$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc)" \
      tools/build_export_templates.sh \
      .r36s-toolchain/godot-src \
      .r36s-toolchain/templates \
      linux-arm64
fi

# Install the exact stock templates, then overlay the project's stripped one.
template_dir="${HOME}/.local/share/godot/export_templates/${GODOT_TEMPLATE_DIR}"
mkdir -p "$template_dir"

if [ ! -f "$template_dir/version.txt" ]; then
    tmp=".r36s-toolchain/templates.tpz"
    curl -fL "$BASE_URL/Godot_v${GODOT_VERSION}_export_templates.tpz" -o "$tmp"
    rm -rf .r36s-toolchain/stock-templates
    mkdir -p .r36s-toolchain/stock-templates
    unzip -q "$tmp" -d .r36s-toolchain/stock-templates
    cp -R .r36s-toolchain/stock-templates/templates/. "$template_dir/"
fi

cp -f .r36s-toolchain/templates/linux_release.arm64 "$template_dir/linux_release.arm64"

# Import once, then export the dedicated preset.
"$GODOT_BIN" --headless --editor --path . --quit
rm -rf builds/r36s
mkdir -p builds/r36s

"$GODOT_BIN" --headless --path . \
    --export-release "Linux ARM64 R36S" \
    "builds/r36s/pokerecomp-r36s.arm64"

test -s builds/r36s/pokerecomp-r36s.arm64
chmod +x builds/r36s/pokerecomp-r36s.arm64

# Build the PortMaster-ready folder. The executable has the PCK embedded, so no
# separate game data or ROM is included.
rm -rf dist/PokeRecomp-R36S
mkdir -p dist/PokeRecomp-R36S/pokerecomp-r36s

cp builds/r36s/pokerecomp-r36s.arm64 \
   dist/PokeRecomp-R36S/pokerecomp-r36s/pokerecomp-r36s
cp r36s/port/PokeRecomp.sh \
   dist/PokeRecomp-R36S/PokeRecomp.sh
cp r36s/port/port.json \
   dist/PokeRecomp-R36S/pokerecomp-r36s/port.json
cp r36s/port/README.md \
   dist/PokeRecomp-R36S/pokerecomp-r36s/README.md

chmod +x dist/PokeRecomp-R36S/PokeRecomp.sh

(
    cd dist/PokeRecomp-R36S
    zip -qry ../PokeRecomp-R36S.zip .
)

sha256sum dist/PokeRecomp-R36S.zip > dist/PokeRecomp-R36S.zip.sha256

echo
echo "=============================================="
echo "R36S BUILD COMPLETE"
echo "=============================================="
ls -lh dist/PokeRecomp-R36S.zip
