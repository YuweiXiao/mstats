# mstats App Store Submission Guide

This project now supports an App Store-ready Xcode app target via `xcodegen`.

## What Was Added

- Xcode project spec: `project.yml`
- Generated project: `MacStatsBar.xcodeproj`
- App Store app entrypoint: `AppStore/AppMain.swift`
- App metadata plist: `AppStore/Info.plist`
- Sandbox entitlements (no extra permissions): `AppStore/MacStatsBar.entitlements`
- App icon resource (from `mac_stat_icon.png`): `AppStore/Resources/AppIcon.icns`

## Prerequisites

- Apple Developer Program membership
- App record created in App Store Connect
- Xcode installed at `/Applications/Xcode.app`
- `xcodegen` installed (`brew install xcodegen`)
- A unique bundle identifier (replace default `dev.mstats.app`)

## One-Time Project Setup

1. Regenerate the project when `project.yml` changes:

```bash
xcodegen generate
```

2. Open `MacStatsBar.xcodeproj` in Xcode.
3. Select target `MacStatsBarStoreApp` and set:
- `Signing & Capabilities` -> Team
- `Signing & Capabilities` -> Bundle Identifier (unique)
- `General` -> Version (`MARKETING_VERSION`)
- `General` -> Build (`CURRENT_PROJECT_VERSION`)

## Validate Locally

Run tests through Xcode build system:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MacStatsBar.xcodeproj \
  -scheme MacStatsBarStore \
  -configuration Debug \
  -destination 'platform=macOS' \
  test
```

## Create Release Archive

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MacStatsBar.xcodeproj \
  -scheme MacStatsBarStore \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath build/MacStatsBar.xcarchive \
  archive
```

Then upload from Xcode Organizer:

1. `Window` -> `Organizer`
2. Select `mstats` archive
3. `Distribute App` -> `App Store Connect` -> `Upload`

## App Store Connect Checklist

- App privacy questionnaire completed
- Privacy policy URL set
- macOS screenshots uploaded
- Description, keywords, support URL filled
- Age rating and category configured
- Release notes written

## Notes

- App Sandbox is enabled with only `com.apple.security.app-sandbox`.
- No extra macOS permission entitlements are requested.
- Keep `LSUIElement = true` in `AppStore/Info.plist` for menu bar behavior.
