# Contributing to bun-ppc64le-port

Thanks for helping improve the Bun ppc64le porting notes, scripts, and patches. This repository is intended to keep reproducible build steps and patch references for getting Bun and JavaScriptCore working on ppc64le systems.

## Getting started

1. Fork and clone the repository.
2. Read `README.md` for the current status and build flow.
3. Review the existing directories before adding new material:
   - `bun-patches/` for Bun-specific patch notes or patch files.
   - `jsc-patches/` for JavaScriptCore/WebKit patch notes or patch files.
   - `notes/` for investigation notes, logs, and architecture-specific findings.
4. Use a feature branch with a descriptive name, for example:

```bash
git checkout -b docs/update-jsc-build-notes
```

## Development workflow

- Keep changes focused on one topic per pull request.
- Prefer reproducible instructions over one-off notes.
- When changing `build-jsc-ppc64le.sh`, run shell syntax checks before opening a PR:

```bash
bash -n build-jsc-ppc64le.sh
```

- If you tested on real hardware or an emulator, include the platform details in the PR:
  - distro and version
  - kernel version
  - compiler versions
  - CPU or VM provider
  - exact command used
  - relevant log excerpt or failure mode

## Documentation style

- Use clear headings and short command blocks.
- Prefer relative paths that work from the repository root.
- Mark uncertain findings as hypotheses instead of facts.
- Include upstream links for WebKit, Bun, Zig, or distro-specific patches when available.
- Do not commit secrets, API tokens, private hostnames, or full logs containing credentials.

## Patch guidelines

When adding or updating patch files:

- Explain what the patch changes and why ppc64le needs it.
- Include the upstream commit, issue, or PR if one exists.
- Keep generated artifacts out of the repository unless they are required for review.
- Avoid large binary files.

## Pull request checklist

Before requesting review, confirm:

- [ ] The change is limited to the documented scope.
- [ ] Commands and paths in documentation were checked.
- [ ] Shell scripts pass `bash -n` when modified.
- [ ] New notes include enough environment details to reproduce the result.
- [ ] External sources are linked where relevant.

## Reporting issues

For build failures, please include:

- Host environment details.
- Bun/WebKit/Zig versions or commit hashes.
- The failing command.
- The first relevant compiler or linker error.
- Any local patches applied.

Small, well-documented reports are easier to reproduce and fix than large unfiltered logs.
