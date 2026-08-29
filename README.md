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

## Selective installation

Pi's official package installer does not show an interactive dependency picker. To install only selected features, install their existing packages directly:

```bash
pi install npm:@narumitw/pi-plan-mode
pi install npm:@narumitw/pi-goal
pi install npm:pi-sandbox
```

Use `pi config` to enable or disable resources from installed packages.

Global settings and `AGENTS.md` are intentionally not managed by this package.
