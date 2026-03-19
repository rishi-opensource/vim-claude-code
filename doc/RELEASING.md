# Semantic Release Guide

This repository uses automated [semantic-release](https://github.com/semantic-release/semantic-release) to handle version bumping, GitHub Release creation, and `CHANGELOG.md` generation.

## How it Works
When a Pull Request is merged into the `main` branch, the `semantic-release` GitHub Action bot reads the git commit history and calculates the next version number automatically based strictly on the **Conventional Commits** specification.

Here is how you should prefix your PR merge commits to control the versions:

* `feat: ...` ➔ **Minor Release** (e.g., `v1.2.0` → `v1.3.0`). Use this when adding a new feature or command.
* `fix: ...` ➔ **Patch Release** (e.g., `v1.2.0` → `v1.2.1`). Use this when fixing a bug or resolving an error.
* `feat!: ...` or including `BREAKING CHANGE:` in the footer ➔ **Major Release** (e.g., `v1.2.0` → `v2.0.0`). Use this when making backwards-incompatible structural or configuration changes.
* `chore:`, `docs:`, `refactor:`, `test:`, `build:`, `ci:` ➔ **No Release**. Use these for internal maintenance tasks that shouldn't trigger a new plugin release for end users.

Once a tagged commit is detected (like `feat:`), the bot will autonomously update the `README.md` version badges, generate a beautiful release Changelog, cut the Git Tag natively, and securely publish everything to GitHub using the Action's `$GITHUB_TOKEN`.
