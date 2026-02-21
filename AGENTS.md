# Repository Guidelines

## Project Structure & Module Organization
- `Sources/MacStatsBar/`: main app module (menu bar UI, popover, domain models, services, collectors).
- `Sources/MacStatsBarApp/`: executable entrypoint target (`MacStatsBarApp`).
- `Tests/MacStatsBarTests/`: unit and behavior tests for formatters, controllers, stores, and view models.
- `AppStore/`: App Store packaging entrypoint, plist, entitlements, and icon resources.
- `scripts/build_app_bundle.sh`: local `.app` bundle builder.
- `images/`: repository image assets (README preview, app icon source).
- `docs/`: release and testing documentation.

## Build, Test, and Development Commands
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
Runs the full SwiftPM test suite.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build --product MacStatsBarApp`
Builds the local executable target.
- `./scripts/build_app_bundle.sh`
Builds and packages `dist/mstats.app` for local run/release zipping.
- `xcodegen generate`
Regenerates `MacStatsBar.xcodeproj` from `project.yml` for App Store workflow.

## Coding Style & Naming Conventions
- Language: Swift 5.10, macOS 14+.
- Indentation: 4 spaces; keep functions focused and avoid deep nesting.
- Types/protocols: `UpperCamelCase`; methods/properties: `lowerCamelCase`.
- Prefer explicit, domain-oriented names (`StatsSnapshot`, `SummaryFormatter`, `MetricHistoryStore`).
- Keep user-facing strings consistent with product name `mstats`.

## Testing Guidelines
- Framework: `XCTest`.
- Add or update tests for every behavior change (formatter output, status-bar rendering, settings behavior).
- Test naming pattern: `test<Behavior>`.
- Before commit/PR, run full suite and ensure zero failures.
- For UI-visible changes, include a deterministic assertion in tests when possible.

## Commit & Pull Request Guidelines
- Follow existing commit style: conventional prefixes such as `feat:`, `fix:`, `docs:`, `build:`.
- Use imperative, scoped messages (example: `feat: compact network formatting in status bar`).
- PRs should include:
- concise summary of behavior changes,
- verification commands run (for example, `swift test`),
- screenshots for UI updates (menu bar/popover),
- linked issue/task when applicable.

## Security & Configuration Notes
- Keep sandbox footprint minimal; do not add extra macOS permission entitlements without discussion.
- Keep bundle identifiers, signing team, and version fields aligned across `project.yml`, `AppStore/Info.plist`, and release artifacts.
