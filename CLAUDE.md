# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

All commands require the `DEVELOPER_DIR` prefix:

```bash
# Run full test suite
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test

# Run a single test class
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter StatsStoreTests

# Build executable
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build --product MacStatsBarApp

# Build distributable .app bundle → dist/mstats.app
./scripts/build_app_bundle.sh

# Generate Xcode project for App Store workflow
xcodegen generate
```

After major code or UI changes, always run `./scripts/build_app_bundle.sh` to verify bundle creation succeeds.

## Architecture

**mstats** is a native macOS menu bar app (Swift 5.10, macOS 14+, no external dependencies). It monitors CPU, memory, network, battery, and disk metrics.

### Data Flow

1. **AppDelegate** initializes `StatsStore` with a `SystemStatsCollector` and starts polling (3s background, 1s when popover is open)
2. **StatsStore** calls `collector.collect()` on each tick, publishes `@Published var currentSnapshot: StatsSnapshot`
3. **StatusBarController** subscribes to snapshots, formats via `SummaryFormatter`, renders in NSStatusBar
4. **PopoverRootView** (SwiftUI) shows detailed metric cards when the status item is clicked
5. **MetricHistoryStore** maintains a 15-minute rolling window of samples for trend sparklines

Sleep/wake lifecycle: polling stops on sleep, resumes on wake.

### Module Layout

- **Domain/** — Value types: `MetricKind` (5 metrics enum), `MetricValue` (value + unit), `StatsSnapshot` (timestamped metrics + process data), `UserPreferences`
- **Services/** — `StatsStore` (polling + Combine publisher), `PreferencesStore` (UserDefaults wrapper), `LoginItemService`, `MetricHistoryStore`
- **Services/Collectors/** — Protocol `StatsCollecting` with `collect() async` method. `SystemStatsCollector` composes individual collectors (CPU, Memory, Network, Battery, Disk) that use mach APIs, IOKit, POSIX, and ifaddrs. Each returns optional values for partial-failure tolerance.
- **MenuBar/** — `StatusBarController` (NSStatusBar + popover management), `SummaryFormatter` (compact text formatting), `SummarySelectionEngine` (picks top N metrics to display)
- **UI/** — SwiftUI views: `PopoverRootView`, `SettingsView`, metric card views, `PopoverViewModel`

### Key Design Patterns

- **Protocol-based collectors** (`StatsCollecting`) enable `FakeStatsCollector` for testing
- **Combine reactive updates** — `@Published` snapshot, UI subscribes via `.sink()`
- **Network rate derivation** — raw byte counters → delta math in StatsStore (handles underflow/NaN)
- **Dependency injection** — all services accept protocol deps in `init()` for testability

## Conventions

- Swift 5.10, macOS 14+, 4-space indentation
- Types/protocols: `UpperCamelCase`; methods/properties: `lowerCamelCase`
- User-facing product name: **mstats** (lowercase)
- Tests: XCTest, naming pattern `test<Behavior>`, use `FakeStatsCollector`/`SequencedStatsCollector` for mocking
- Commits: conventional prefixes (`feat:`, `fix:`, `docs:`, `build:`), imperative mood
- Default branch: `main`
- Minimal sandbox entitlements — do not add macOS permissions without discussion
- Keep bundle identifiers, signing team, and version aligned across `project.yml`, `AppStore/Info.plist`, and release artifacts

## Two Build Targets

- **SwiftPM** (`Package.swift`): library `MacStatsBar` + executable `MacStatsBarApp` — used for local dev/testing
- **Xcode project** (`project.yml` → `xcodegen generate`): `MacStatsBarStoreApp` — used for App Store archive/upload
