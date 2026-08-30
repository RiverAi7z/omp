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
- `@riverai7z/pi-todo`
- `pi-sandbox`
- `pi-simplify`
- `extensions/tools.ts`

## Interactive installation

Review [`install.sh`](./install.sh), then run it directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/riverai7z/omp/master/install.sh | bash
```

The installer displays an interactive checkbox menu using each plugin's npm package name. Use ↑/↓ to move, Space to toggle `[ ]`/`[x]`, and Enter to install the selected plugins. It also includes `pi-web-access`. npm plugins are installed through `pi install`; the local `extensions/tools.ts` extension is downloaded to `~/.pi/agent/extensions/tools.ts`.

To install from a fork or another branch:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/BRANCH/install.sh \
  | OMP_GITHUB_REPO=OWNER/REPO OMP_GITHUB_REF=BRANCH bash
```

Use `pi config` to enable or disable resources after installation. Re-run the installer to update the local `Tools` extension.

Global settings and `AGENTS.md` are intentionally not managed by this package.
