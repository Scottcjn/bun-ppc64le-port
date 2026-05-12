# Contributing

Thanks for helping improve the Bun ppc64le port. This project is platform
specific, so contributions should be careful about reproducibility, toolchain
versions, and hardware assumptions.

## Local Setup

Clone the repository:

```bash
git clone https://github.com/Scottcjn/bun-ppc64le-port.git
cd bun-ppc64le-port
```

Review the existing build notes before changing patches, scripts, or
documentation.

## Contribution Guidelines

- Keep POWER/ppc64le compatibility details explicit.
- Document compiler, OS, and hardware assumptions.
- Avoid mixing unrelated patch, build, and documentation changes in one PR.
- Preserve reproducibility notes when updating build instructions.
- Include links to upstream issues or commits when changing porting patches.

## Validation

For documentation-only changes:

```bash
git diff --check
```

For build or patch changes, include the exact build command, platform details,
and the result in the pull request. If you cannot run the full build locally,
state what was validated and what remains untested.

## Pull Request Checklist

- Explain the affected build stage or documentation section.
- Include validation commands and platform details.
- Note any known limitations.
- Link the related issue or bounty, if applicable.
