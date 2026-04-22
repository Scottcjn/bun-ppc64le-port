# Bun ppc64le Port — Plan

## Commit
Scott approved 2026-04-21. Target: working Bun runtime on POWER8 + Claude Code
running on it (replaces v2.1.112 SEA pin).

## Architecture
```
Layer 1: Toolchain      [clang-18 + libc++-18]  ✅ working
Layer 2: JSC (CLOOP)    [C++23 interpreter]     🔄 building
Layer 3: Zig ppc64le    [bootstrap + cross]     pending
Layer 4: Bun build.zig  [ppc64le target switch] pending
Layer 5: Bun runtime    [bindings + asm paths]  pending
Layer 6: Claude Code    [Bun-compiled SEA]      pending
```

## Phase Gates
- **Gate 0 — Toolchain** ✅ libc++-18 + ICU 72 + clang-18
- **Gate 1 — JSC CLOOP builds** ✅ upstream 502/502
- **Gate 2 — JSC runs jsc REPL** ✅ ES6+ verified
- **Gate 2.5 — Oven-sh fork + Bun flags** ✅ libJSC.a 38MB installed at
  /opt/bun-webkit-ppc64le, ES2022+ async gen verified
- **Gate 3 — Bun build sees our WebKit** → BUN_WEBKIT_PATH or new prebuilt-local mode
- **Gate 4a — Bun Zig artifact** — CRITICAL BLOCKER
  - Option A: Build Zig from source on POWER8 (unstable, ziglang/zig#24568)
  - Option B: Cross-compile bun-zig.o from x86 host via Zig master
  - Option C: **Write minimal `jsc-runner` (~1k LOC C++) bypassing Zig entirely**
- **Gate 4b — Bun compile + link** → C++ bindings against libJSC.a
- **Gate 5 — `bun --version` works**
- **Gate 6 — `bun run` a script**
- **Gate 7 — Claude Code runs**

## Alternative: jsc-runner micro-runtime
If Zig-on-POWER8 proves too painful, build a minimal C++ runtime:
- Links our libJavaScriptCore.a directly
- Accepts a .js file path, creates JSGlobalObject, evaluates
- Minimal bindings: process.argv, fs, Buffer, http via libuv + WTF
- Claude Code's SEA-extracted bundle runs without needing Bun's full surface
- Estimated effort: ~1-2 weeks vs Bun's 2-3 months
- Trade-off: Claude Code tracks Bun releases, so we'd re-sync periodically

## Known real gaps (from codex audit)
1. `Source/JavaScriptCore/runtime/MachineContext.h` — Linux mcontext_t only
   handled for x86_64/ARM/ARM64/RISCV64; `#error Unknown Architecture` for ppc64le
   → need `CPU(PPC64LE)` + Linux case mirroring RISCV64 structure (~100 LOC)
2. `Source/cmake/WebKitCommon.cmake:125-130` — regex matches `(ppc|powerpc)`
   BEFORE `ppc64le`, may misclassify → verify at build time what WTF_CPU_X is set
3. `scripts/build/deps/webkit.ts:71-77` — only knows amd64/arm64 prebuilt tarballs
4. `scripts/build/zig.ts` — pinned Zig commits, need to verify they include
   ziglang/zig#24238, #25229, #25231, #25450, #25478 (ppc64le fixes)
5. Zig stage3 still crashes on POWER8 native (#24568) — cross-compile first

## Cross-compile vs native
Codex flagged: "native POWER8 bootstrap is still not boring."
→ **Strategy**: use x86 host as cross-compile donor, ship Bun binary to POWER8.
Same model as SEA — precompiled binary.

## Upstream PRs we'll file
A. WebKit MachineContext.h ppc64le Linux case (landable alone, ~100 LOC)
B. WebKit WebKitCommon.cmake ppc64le arch regex fix (~5 LOC)
C. Bun build.zig + scripts/build ppc64le target switches (~150 LOC)
D. (maybe) Zig ppc64le stage3 fixes if we hit them

## Work dir layout
- `/home/scott/bun-ppc64le-port/jsc-patches/` — upstream-bound patches
- `/home/scott/bun-ppc64le-port/bun-patches/` — Bun build config patches
- `/home/scott/bun-ppc64le-port/notes/` — progress log + decisions
- POWER8 `/tmp/webkit-scout/WebKit/build-jsc-ppc64le/` — live JSC build
