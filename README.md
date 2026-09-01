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

Before showing the interactive checkbox menu, the installer offers to install Pi with the official installer if `pi` is not in `PATH`. After installation, it detects Pi's install directory and adds it to the installer's current `PATH`, so extension installation can continue without restarting the shell.

The installer also checks required command-line dependencies and offers to install any that are missing. On macOS it checks `ripgrep` (`rg`) and installs it with Homebrew. On Linux it checks `ripgrep`, `bubblewrap` (`bwrap`), and `socat`, using a supported system package manager (`apt`, `apk`, `dnf`, `yum`, `pacman`, or `zypper`). Linux system package installation may prompt for a `sudo` password.

The installer then runs `pi list` and checks the local `extensions/tools.ts` path. Already-installed entries are labeled `(installed)`, left unchecked, and cannot be selected again. Among entries that are not installed, all are selected by default except `@riverai7z/pi-read`, `@riverai7z/pi-todo`, and `pi-simplify`; these must be explicitly selected. Default-selected entries are listed first, followed by unchecked entries. `@riverai7z/pi-read` is opt-in because it replaces Pi's built-in `read` tool. Use ↑/↓ to move, Space to toggle `[ ]`/`[x]`, and Enter to install the selected extensions.

npm extensions are installed through `pi install`. The local `extensions/tools.ts` extension is downloaded to `~/.pi/agent/extensions/tools.ts`.

To install from a fork or another branch:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/BRANCH/install.sh \
  | OMP_GITHUB_REPO=OWNER/REPO OMP_GITHUB_REF=BRANCH bash
```

Use `pi config` to enable or disable resources after installation, and `pi update --extensions` to update installed npm packages. Delete the local `extensions/tools.ts` file before running the installer if you want to download it again.

Global settings and `AGENTS.md` are intentionally not managed by this installer.
