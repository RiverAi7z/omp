# omp

A script-based installer for a personal collection of Pi extensions.

## Installation

Review [`install.sh`](./install.sh), then run it directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/riverai7z/omp/master/install.sh | bash
```

The installer offers:

- `@juicesharp/rpiv-ask-user-question`
- `@narumitw/pi-btw`
- `@narumitw/pi-goal`
- `@narumitw/pi-plan-mode`
- `@riverai7z/pi-read`
- `@riverai7z/pi-todo`
- `pi-sbx`
- `pi-simplify`
- `pi-web-access`
- `extensions/tools.ts`

Before showing the interactive checkbox menu, the installer runs `pi list` and checks the local `extensions/tools.ts` path. Already-installed entries are labeled `(installed)`, left unchecked, and cannot be selected again. Among entries that are not installed, all are selected by default except `@riverai7z/pi-read`, which must be explicitly selected because it replaces Pi's built-in `read` tool. Use ↑/↓ to move, Space to toggle `[ ]`/`[x]`, and Enter to install the selected extensions.

npm extensions are installed through `pi install`. The local `extensions/tools.ts` extension is downloaded to `~/.pi/agent/extensions/tools.ts`.

To install from a fork or another branch:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/BRANCH/install.sh \
  | OMP_GITHUB_REPO=OWNER/REPO OMP_GITHUB_REF=BRANCH bash
```

Use `pi config` to enable or disable resources after installation, and `pi update --extensions` to update installed npm packages. Delete the local `extensions/tools.ts` file before running the installer if you want to download it again.

Global settings and `AGENTS.md` are intentionally not managed by this installer.
