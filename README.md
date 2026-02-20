# mstats

Lightweight macOS menu bar monitor for live CPU, memory, network, battery, and disk stats.

<img src="images/demo.png" alt="mstats app preview" width="320" />

## Scope

Current implementation includes:
- Core metrics domain + formatting (`CPU`, `Memory`, `Network`, `Battery`, `Disk`)
- Polling `StatsStore` with lifecycle handling (sleep/wake)
- System collectors with partial-failure tolerance
- Menu bar summary selection/rendering (max-two auto-fit)
- Popover view-model and settings/detail UI components
- Preferences persistence and login-item service abstraction

## Download And Run (End Users)

1. Download the latest `mstats.app.zip` from GitHub Releases.
2. Unzip and move `mstats.app` to `/Applications`.
3. Launch with Finder or:

```bash
open /Applications/mstats.app
```

If macOS blocks first launch, right-click the app and choose `Open`.

## Build And Test (Developers)

### Prerequisites

- macOS 14+
- Xcode installed at `/Applications/Xcode.app`
- Swift toolchain compatible with `SWIFT_VERSION = 5.10`
- `xcodegen` for App Store project generation (`brew install xcodegen`)

This repo is organized as a Swift package.

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
open dist/mstats.app
```

## App Store Project

Generate the Xcode project used for App Store archive/upload:

```bash
xcodegen generate
```

Then open:

```bash
open MacStatsBar.xcodeproj
```

For end-to-end submission steps, see:

- `docs/release/app-store-submission.md`

## Manual Validation

Manual QA checklist: `docs/testing/manual-test-checklist.md`

## Notes

- Local bundle workflow exists in `scripts/build_app_bundle.sh` and outputs `dist/mstats.app`.
- App Store workflow now uses `MacStatsBarStoreApp` in `MacStatsBar.xcodeproj`.

## License

MIT. See `LICENSE`.
