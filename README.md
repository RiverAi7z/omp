# omp

A personal Pi package collection containing the local `tools` extension and selected third-party Pi packages.

## Full collection

Install every extension in the collection from npm:

```bash
pi install npm:@riverai7z/omp
```

Or install from a local checkout:

```bash
pi install /absolute/path/to/omp
```

The collection includes:

- `@juicesharp/rpiv-ask-user-question`
- `@narumitw/pi-btw`
- `@narumitw/pi-goal`
- `@narumitw/pi-plan-mode`
- `@riverai7z/pi-read`
- `@riverai7z/pi-todo`
- `pi-sandbox`
- `pi-simplify`
- `extensions/tools.ts`

## Interactive installation

Review [`install.sh`](./install.sh), then run it directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/riverai7z/omp/master/install.sh | bash
```

Before showing the interactive checkbox menu, the installer runs `pi list` and checks the local `extensions/tools.ts` path. Already-installed entries are labeled `(installed)`, left unchecked, and cannot be selected again. Among entries that are not installed, all are selected by default except `@riverai7z/pi-read`, which must be explicitly selected because it replaces Pi's built-in `read` tool. Use ↑/↓ to move, Space to toggle `[ ]`/`[x]`, and Enter to install the selected plugins. It also includes `pi-web-access`. npm plugins are installed through `pi install`; the local `extensions/tools.ts` extension is downloaded to `~/.pi/agent/extensions/tools.ts`.

To install from a fork or another branch:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/BRANCH/install.sh \
  | OMP_GITHUB_REPO=OWNER/REPO OMP_GITHUB_REF=BRANCH bash
```

Use `pi config` to enable or disable resources after installation, and `pi update --extensions` to update installed npm packages. Delete the local `extensions/tools.ts` file before running the installer if you want to download it again.

Global settings and `AGENTS.md` are intentionally not managed by this package.
