#!/usr/bin/env bash
# Reproducible build: oven-sh/WebKit JSC on ppc64le with all Bun flags.
#
# Requires (on Ubuntu 20.04 ppc64el host):
#   apt install clang-18 libc++-18-dev libc++abi-18-dev libunwind-18-dev \
#               ruby-full cmake ninja-build git wget tar build-essential
#
# Produces:
#   $OUT/lib/libJavaScriptCore.a (~38 MB with Bun additions)
#   $OUT/lib/libWTF.a, lib/libbmalloc.a
#   $OUT/bin/jsc
#
# Usage: ./build-jsc-ppc64le.sh [build-dir]

set -euo pipefail

OUT="${1:-/tmp/bun-webkit-build}"
WEBKIT_COMMIT="4d5e75ebd84a14edbc7ae264245dcd77fe597c10"  # matches bun/scripts/build/deps/webkit.ts
ICU_VERSION="72-1"

HERE="$(cd "$(dirname "$0")" && pwd)"
PATCHES="$HERE/jsc-patches"

# ───────────────────────────────────────────────────────────────────────────
# 1. ICU 72 (Ubuntu 20.04 apt only ships 66.1; oven-sh/WebKit needs 70.1+)
# ───────────────────────────────────────────────────────────────────────────
if [ ! -f /opt/icu-72/lib/libicui18n.so ]; then
    echo "=== Building ICU $ICU_VERSION from source ==="
    mkdir -p /tmp/icu-build && cd /tmp/icu-build
    [ -f icu4c-${ICU_VERSION}-src.tgz ] || wget -q \
        "https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION}/icu4c-${ICU_VERSION//-/_}-src.tgz"
    tar xzf icu4c-${ICU_VERSION}-src.tgz
    cd icu/source
    ./configure --prefix=/opt/icu-72 --disable-tests --disable-samples \
                --enable-static --enable-shared
    make -j"$(nproc)"
    sudo make install
fi

# ───────────────────────────────────────────────────────────────────────────
# 2. Clone oven-sh/WebKit + checkout pinned commit
# ───────────────────────────────────────────────────────────────────────────
WEBKIT_SRC="${WEBKIT_SRC:-/tmp/oven-webkit}"
if [ ! -d "$WEBKIT_SRC/.git" ]; then
    echo "=== Cloning oven-sh/WebKit (shallow) ==="
    git clone --depth 1 --no-checkout https://github.com/oven-sh/WebKit.git "$WEBKIT_SRC"
fi

cd "$WEBKIT_SRC"
if [ "$(git rev-parse HEAD 2>/dev/null)" != "$WEBKIT_COMMIT" ]; then
    git fetch --depth 1 origin "$WEBKIT_COMMIT"
    git checkout "$WEBKIT_COMMIT"
fi

# ───────────────────────────────────────────────────────────────────────────
# 3. Apply 5 patches
# ───────────────────────────────────────────────────────────────────────────
if ! grep -q "friend class JSC::LLIntOffsetsExtractor" \
        Source/JavaScriptCore/bytecode/ArithProfile.h \
        | grep -q "3$"; then  # check patches applied
    echo "=== Applying 5 JSC patches ==="
    if [ -f "$PATCHES/000-all-combined.diff" ]; then
        git apply "$PATCHES/000-all-combined.diff" 2>&1 || {
            echo "Combined diff failed; applying individual patches..."
            git apply "$PATCHES"/00[1-5]-*.patch
        }
    else
        git apply "$PATCHES"/00[1-5]-*.patch
    fi
fi

# ───────────────────────────────────────────────────────────────────────────
# 4. Configure with ppc64le CLOOP + Bun flags
# ───────────────────────────────────────────────────────────────────────────
BUILD_DIR="$WEBKIT_SRC/build-ppc64le"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -f CMakeCache.txt ]; then
    echo "=== cmake configure ==="
    cmake -GNinja .. \
        -DPORT=JSCOnly \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_STATIC_JSC=ON \
        -DUSE_THIN_ARCHIVES=OFF \
        -DENABLE_FTL_JIT=OFF \
        -DENABLE_JIT=OFF \
        -DENABLE_DFG_JIT=OFF \
        -DENABLE_C_LOOP=ON \
        -DENABLE_WEBASSEMBLY=OFF \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DUSE_BUN_JSC_ADDITIONS=ON \
        -DUSE_BUN_EVENT_LOOP=ON \
        -DENABLE_BUN_SKIP_FAILING_ASSERTIONS=ON \
        -DALLOW_LINE_AND_COLUMN_NUMBER_IN_BUILTINS=ON \
        -DENABLE_REMOTE_INSPECTOR=ON \
        -DENABLE_MEDIA_SOURCE=OFF \
        -DENABLE_MEDIA_STREAM=OFF \
        -DENABLE_WEB_RTC=OFF \
        -DUSE_SYSTEM_MALLOC=ON \
        -DCMAKE_C_COMPILER=clang-18 \
        -DCMAKE_CXX_COMPILER=clang++-18 \
        -DCMAKE_CXX_FLAGS="-stdlib=libc++ -mcpu=power8" \
        -DCMAKE_C_FLAGS="-mcpu=power8" \
        -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++" \
        -DCMAKE_SHARED_LINKER_FLAGS="-stdlib=libc++" \
        -DICU_ROOT=/opt/icu-72 \
        -DUSE_LIBBACKTRACE=OFF
fi

# ───────────────────────────────────────────────────────────────────────────
# 5. Build jsc (produces lib/libJavaScriptCore.a + bin/jsc)
# ───────────────────────────────────────────────────────────────────────────
echo "=== ninja jsc ==="
ninja -j "$(nproc)" jsc

# ───────────────────────────────────────────────────────────────────────────
# 6. Install to $OUT
# ───────────────────────────────────────────────────────────────────────────
mkdir -p "$OUT"
cp -r lib bin "$OUT/"
cp -r "$WEBKIT_SRC"/Source/WTF/Headers "$OUT/WTF-Headers" 2>/dev/null || true
cp -r ./JavaScriptCore "$OUT/"
cp -r ./WTF "$OUT/"
cp -r ./bmalloc "$OUT/"

echo ""
echo "✅ JSC build complete. Artifacts in $OUT:"
ls -la "$OUT/lib/" "$OUT/bin/"

echo ""
echo "=== Smoke test ==="
LD_LIBRARY_PATH=/opt/icu-72/lib "$OUT/bin/jsc" -e 'print("JSC on ppc64le:", 2+2, typeof Promise.resolve)'
