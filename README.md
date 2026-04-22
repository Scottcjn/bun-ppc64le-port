# bun-ppc64le-port

Porting [Bun](https://github.com/oven-sh/bun) and [WebKit/JavaScriptCore](https://github.com/oven-sh/WebKit) to **ppc64le** (IBM POWER8+ Linux).

## Status (2026-04-22)

| Gate | Status | Notes |
|------|--------|-------|
| 0 — Toolchain | ✅ | libc++-18, ICU 72 (from source), clang-21.1.4, ld.lld |
| 1 — JSC CLOOP builds | ✅ | Upstream WebKit + oven-sh/WebKit fork, 0 failures |
| 2 — JSC runs full ES2022+ | ✅ | Classes, generators, Map/Set, Promise, async iterators verified |
| 2.5 — Bun-flags JSC | ✅ | libJSC 38MB with USE_BUN_JSC_ADDITIONS et al. |
| 3 — Zig for ppc64le | ✅ | Official Zig 0.16.0 binary from ziglang.org works natively |
| 4a — Bun's codegen needs bun | 🔄 | Chicken-and-egg: bun binary needed to build bun |
| 4b — Bun compile + link | ⏳ | Next |
| 5-7 — `bun --version` / `bun run` / Claude Code | ⏳ | |

**Everything JSC-side is reproducible today.** See `build-jsc-ppc64le.sh`.

## Toolchain requirements (Ubuntu 20.04 ppc64el host)

```bash
apt install clang-18 libc++-18-dev libc++abi-18-dev libunwind-18-dev \
            ruby-full cmake ninja-build git wget curl tar build-essential
```

Built from source (script-automated):
- **ICU 72** — Ubuntu 20.04 apt caps at 66.1; oven-sh/WebKit needs 70.1+
- **LLVM/Clang 21.1.4** — Bun's build system requires `clang>=21.1.0 <21.1.99`

Downloaded (official prebuilt):
- **Zig 0.16.0** for ppc64le-linux from [ziglang.org](https://ziglang.org/download/)

## Patches

### JSC patches (5, all upstream-landable, none ppc64le-specific)

All fix clang-18+libc++ hygiene issues that affect any modern JSC CLOOP build:

| # | Patch | Fixes |
|---|-------|-------|
| 1 | `ArithProfile` friend + forward decl | clang-18 strict qualified-friend lookup |
| 2 | `cloop.rb` `jsCast` → `uncheckedDowncast` | removed-API reference in codegen |
| 3 | `Heap.cpp` `<wtf/SetForScope.h>` include | transitive-include loss on CLOOP |
| 4 | `DeferredWorkTimer.cpp` same include | same class as #3 |
| 5 | `DFGAbstractHeap.h` split enum out of `#if ENABLE(DFG_JIT)` | DOMJIT needs enum unconditionally |

Combined diff: `jsc-patches/000-all-combined.diff` (98 lines, 5 files).

### Bun patches (4, drafted + type-check clean)

| # | Patch | Scope |
|---|-------|-------|
| 1 | `config.ts` | Add `"ppc64le"` to `Arch` union + `Config.ppc64le` |
| 2 | `deps/webkit.ts` | Local CLOOP mode on ppc64le, skip prebuilt tarball |
| 3 | `flags.ts` | `-mcpu=power8 -mtune=power8` |
| 4 | `src/env.zig` | `Architecture` enum + string map + comptime dispatch |

## Reproducible JSC build

```bash
./build-jsc-ppc64le.sh /opt/bun-webkit-ppc64le
```

Produces in ~30 min on 32 threads:
- `/opt/bun-webkit-ppc64le/lib/libJavaScriptCore.a` (~38 MB, Bun additions baked in)
- `/opt/bun-webkit-ppc64le/lib/libWTF.a` (~3.6 MB)
- `/opt/bun-webkit-ppc64le/lib/libbmalloc.a` (~180 KB)
- `/opt/bun-webkit-ppc64le/bin/jsc` (~18 MB) — smoke tests execute

Smoke test from `jsc`:

```
$ jsc -e 'class T { async *[Symbol.asyncIterator]() { yield 1; yield 2 } }; \
         const t = new T(); \
         (async () => { for await (const v of t) print(v) })()'
1
2
```

## Key finding: codex-predicted `MachineContext.h` gap never hit

[Codex audit](https://github.com/Scottcjn/bun-ppc64le-port/blob/main/notes/codex-audit-pointer.md) flagged `Source/JavaScriptCore/runtime/MachineContext.h:192-..` as a real ppc64le source gap needing ~100 LOC of mcontext handling. In practice, those `#error Unknown Architecture` sites live inside `ENABLE_JIT` / `ENABLE_DFG_JIT` / `ENABLE_FTL_JIT` regions. CLOOP mode compiles them out entirely. Signal-based preemption via mcontext is JIT-only.

**Implication**: the existing WTF ppc64le scaffolding (`PlatformCPU.h`, `PageBlock.h` 64KiB target, `WebKitFeatures.cmake` CLOOP autoselect) was sufficient. JSC's arch-agnostic code path is genuinely complete.

## Chicken-and-egg on Gate 4a

Bun's build system (`scripts/build.ts`) requires a `bun` binary for codegen (bundling internal modules via `bun build`, installing deps via `bun install`). Bun's official releases have no ppc64le. `npm install bun` rejects with `"cpu":"ppc64"` restriction in package.json.

Resolution options:
1. Codegen on x86 host (has bun), rsync generated C++/TS sources to POWER8
2. Build Bun on x86 host cross-targeting ppc64le via `--os=linux --arch=ppc64le`
   (x86 host needs clang-21 installed first)
3. Patch Bun's build system to fall back to `node` for codegen scripts

## Layout

```
.
├── README.md                       # this file
├── build-jsc-ppc64le.sh            # reproducible JSC build script
├── bun-patches/                    # 4 Bun source patches
├── jsc-patches/                    # 5 oven-sh/WebKit patches + combined diff
└── notes/
    ├── plan.md                     # gate plan + architecture
    └── progress.log                # per-session build-by-build log
```

## License

Patches and build scripts are licensed MIT. See individual patches for header
attribution of the code they modify (Apple Inc. copyright preserved in WebKit
patches per upstream convention).
