# Contributing to Battery Menu

[English](CONTRIBUTING.md) · [简体中文](CONTRIBUTING.zh-CN.md)

Thanks for helping improve Battery Menu. Hardware telemetry differs across Mac
models, so compatibility reports and focused fixes are especially valuable.
By submitting a contribution, you agree that it may be distributed under the
project's [MIT License](LICENSE).

## Before you start

- Search existing issues before opening a new one.
- Keep changes focused and avoid unrelated formatting rewrites.
- Do not include serial numbers, device identifiers, usernames, or complete
  IORegistry dumps in issues or commits.
- Describe the Mac model and macOS version when reporting telemetry problems.

## Local setup

```bash
git clone https://github.com/985860612/battery-menu.git
cd battery-menu
swift build
swift run battery-dump
```

To assemble the application bundle:

```bash
./scripts/build-app.sh
open "dist/Battery Menu.app"
```

## Pull request checklist

- The Release build completes with `swift build -c release`.
- `./scripts/build-app.sh` creates a valid application bundle.
- New telemetry fields degrade gracefully to `nil` or `—` when unavailable.
- UI changes work in system, light, and dark appearances.
- User-facing behavior and hardware caveats are documented in both READMEs.
- No generated build output from `.build/` or `dist/` is committed.

## Project conventions

- Keep hardware access and parsing in `BatteryCore`.
- Keep UI and preferences in `BatteryMenu`.
- Prefer public macOS APIs; isolate IORegistry compatibility fallbacks.
- Avoid network dependencies and administrator-only behavior.
- Preserve the app's local-only privacy model.

For a bug report, include reproduction steps, expected and actual results, and
redacted `battery-dump` output when it is relevant.
