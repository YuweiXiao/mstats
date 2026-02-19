# MacStatsBar

macOS menu bar stats app in active development.

## Scope

Current implementation includes:
- Core metrics domain + formatting (`CPU`, `Memory`, `Network`, `Battery`, `Disk`)
- Polling `StatsStore` with lifecycle handling (sleep/wake)
- System collectors with partial-failure tolerance
- Menu bar summary selection/rendering (max-two auto-fit)
- Popover view-model and settings/detail UI components
- Preferences persistence and login-item service abstraction

## Build And Test

This repo is currently organized as a Swift package.

Run full test suite:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

Run targeted suites:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter StatsStoreTests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter SystemCollectorMappingTests
```

Build the app executable target:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build --product MacStatsBarApp
```

## Build App Bundle

Create a local `.app` bundle in `dist/`:

```bash
./scripts/build_app_bundle.sh
```

Launch it:

```bash
open dist/MacStatsBar.app
```

## Manual Validation

Manual QA checklist: `docs/testing/manual-test-checklist.md`

## Notes

- Full app-bundle packaging/wiring for production release is still tracked in plan follow-up.
