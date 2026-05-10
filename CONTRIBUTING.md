# Contributing

Thanks for helping move the Bun ppc64le port forward. This repository tracks
reproducible JavaScriptCore and Bun patch work for IBM POWER8+ Linux, so small,
well-documented changes are much easier to review than broad rewrites.

## Getting Started

1. Read `README.md` for the current gate status and known blockers.
2. Read `notes/plan.md` before changing build strategy or patch scope.
3. Work from a fresh branch:

   ```bash
   git checkout -b your-change-name
   ```

4. Keep changes focused on one area:
   - `jsc-patches/` for WebKit/JavaScriptCore patches.
   - `bun-patches/` for Bun source/build-system patches.
   - `build-jsc-ppc64le.sh` for reproducible JSC build changes.
   - `notes/` for investigation logs and decisions.

## Development Workflow

For JSC-related changes, verify the patch still applies cleanly and document the
host used for testing. On a ppc64el host, the expected build command is:

```bash
./build-jsc-ppc64le.sh /opt/bun-webkit-ppc64le
```

If you cannot run the full POWER8 build, say so clearly in the pull request and
include the validation you did run, such as `git apply --check`, shell syntax
checks, or review against the pinned WebKit commit.

## Patch Guidelines

- Preserve upstream copyright headers in WebKit and Bun patches.
- Keep patches small and upstream-landable when possible.
- Name new patches with the next numeric prefix and a short description.
- Update `jsc-patches/000-all-combined.diff` if individual JSC patches change.
- Avoid mixing unrelated JSC, Bun, and documentation work in one PR.

## Code Style

- Shell scripts should use `set -euo pipefail` and quote paths/variables.
- Prefer explicit versions or commit SHAs for reproducibility.
- Use comments for non-obvious ppc64le or POWER8-specific constraints.
- Keep documentation factual and tied to commands or observed build results.

## Pull Request Checklist

Before opening a PR, include:

- A short summary of the gate or blocker affected.
- The exact commands you ran.
- The host architecture and OS used for validation.
- Any build logs, smoke-test output, or known limitations.
- Whether the change is intended for upstream WebKit/Bun or only this port repo.

