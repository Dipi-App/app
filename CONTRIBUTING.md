# Contributing to Dipi

Thanks for your interest in improving Dipi! This guide is short — the goal is to
keep contributions easy to review.

## Getting started

1. Fork the repository and create a topic branch from `main`.
2. Make your change.
3. Run the checks below and make sure they pass.
4. Open a pull request using the provided template.

## Development checks

```bash
flutter pub get
flutter analyze    # must stay clean
flutter test
```

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/): `feat: …`,
`fix: …`, `chore: …`, `docs: …`. A breaking change is marked with `!`
(for example `feat!: …`). Releases are cut from these messages, so keep them
clear and meaningful.

## What to keep in mind

- Persian is the only UI language; the interface is fully RTL and uses Persian
  digits. Match the existing tone and terminology.
- Keep business logic (balance, statistics) in pure Dart classes, not widgets.
- Never commit signing material, keystores, `key.properties` or environment
  files. See [SECURITY.md](SECURITY.md).
- Keep pull requests focused; avoid unrelated refactors.

## Reporting bugs and requesting features

Use the issue templates in `.github/ISSUE_TEMPLATE/`. For security issues, do
**not** open a public issue — follow [SECURITY.md](SECURITY.md).

## Code of Conduct

By participating you agree to follow our
[Code of Conduct](CODE_OF_CONDUCT.md).
