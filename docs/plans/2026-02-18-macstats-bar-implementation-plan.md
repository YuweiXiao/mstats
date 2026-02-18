# MacStats Bar Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS 14+ menu bar app that shows configurable live system stats (CPU, memory, network, battery, disk) with a detailed click popover and no extra permissions.

**Architecture:** Build a native SwiftUI + AppKit hybrid app with a polling `StatsStore` and dedicated collectors for each metric family. Keep domain models pure and testable, isolate OS-specific calls behind protocols, and render both menu bar summary and popover from a single published snapshot stream.

**Tech Stack:** Swift 5.10+, SwiftUI, AppKit (`NSStatusItem`), XCTest, ServiceManagement, Foundation/IOKit/system APIs.

---

## Prerequisites

- Use a dedicated worktree before implementation.
- Follow `@test-driven-development` for each task.
- Before claiming completion, run `@verification-before-completion`.

### Task 1: Bootstrap App Skeleton

**Files:**
- Create: `MacStatsBar.xcodeproj` (or equivalent Xcode project scaffolding)
- Create: `MacStatsBar/App/MacStatsBarApp.swift`
- Create: `MacStatsBar/App/AppDelegate.swift`
- Create: `MacStatsBar/MenuBar/StatusBarController.swift`
- Create: `MacStatsBarTests/AppLaunchSmokeTests.swift`
- Modify: `README.md`

**Step 1: Write the failing smoke test**

```swift
import XCTest
@testable import MacStatsBar

final class AppLaunchSmokeTests: XCTestCase {
    func testStatusBarControllerConstructs() {
        let controller = StatusBarController()
        XCTAssertNotNil(controller)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/AppLaunchSmokeTests/testStatusBarControllerConstructs`
Expected: FAIL (missing `StatusBarController`/target until scaffold is created).

**Step 3: Write minimal implementation**

```swift
import AppKit

final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
}
```

Also add minimal `@main` app and `NSApplicationDelegateAdaptor`.

**Step 4: Run test to verify it passes**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar.xcodeproj MacStatsBar/App MacStatsBar/MenuBar MacStatsBarTests README.md
git commit -m "chore: bootstrap macOS menu bar app skeleton"
```

### Task 2: Define Core Domain Models

**Files:**
- Create: `MacStatsBar/Domain/MetricKind.swift`
- Create: `MacStatsBar/Domain/StatsSnapshot.swift`
- Create: `MacStatsBar/Domain/UserPreferences.swift`
- Create: `MacStatsBar/Domain/MetricValue.swift`
- Test: `MacStatsBarTests/DomainModelsTests.swift`

**Step 1: Write failing tests for model behavior**

```swift
func testUserPreferencesDefaultShowsCpuAndMemory() {
    let prefs = UserPreferences.defaultValue
    XCTAssertEqual(prefs.summaryMetricOrder.prefix(2), [.cpuUsage, .memoryUsage])
}
```

Add tests for codable round-trip and summary cap (`maxVisibleSummaryItems == 2` default behavior).

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/DomainModelsTests`
Expected: FAIL (types not found).

**Step 3: Implement minimal models**

```swift
enum MetricKind: String, Codable, CaseIterable { case cpuUsage, memoryUsage, networkThroughput, batteryStatus, diskUsage }
```

Implement `StatsSnapshot`, `MetricValue`, and `UserPreferences`.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/Domain MacStatsBarTests/DomainModelsTests.swift
git commit -m "feat: add core domain models and defaults"
```

### Task 3: Implement Preferences Storage

**Files:**
- Create: `MacStatsBar/Services/PreferencesStore.swift`
- Test: `MacStatsBarTests/PreferencesStoreTests.swift`

**Step 1: Write failing persistence tests**

```swift
func testSaveAndLoadRoundTrip() throws {
    let store = PreferencesStore(userDefaults: UserDefaults(suiteName: "PreferencesStoreTests")!)
    let input = UserPreferences.defaultValue
    store.save(input)
    XCTAssertEqual(store.load(), input)
}
```

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/PreferencesStoreTests`
Expected: FAIL.

**Step 3: Implement minimal `PreferencesStore`**

Use JSON encode/decode and a stable key like `user_preferences_v1`.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/Services/PreferencesStore.swift MacStatsBarTests/PreferencesStoreTests.swift
git commit -m "feat: add preferences persistence"
```

### Task 4: Add Summary Formatting Logic

**Files:**
- Create: `MacStatsBar/MenuBar/SummaryFormatter.swift`
- Test: `MacStatsBarTests/SummaryFormatterTests.swift`

**Step 1: Write failing formatter tests**

```swift
func testCpuFormatting() {
    let text = SummaryFormatter.formatCPU(23.2)
    XCTAssertEqual(text, "CPU 23%")
}
```

Add tests for memory (`MEM used/total`), network arrows (`NET x↓ y↑`), and unknown placeholder (`--`).

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/SummaryFormatterTests`
Expected: FAIL.

**Step 3: Implement formatter**

Use deterministic rounding and unit conversion helpers for stable labels.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/MenuBar/SummaryFormatter.swift MacStatsBarTests/SummaryFormatterTests.swift
git commit -m "feat: implement summary metric formatting"
```

### Task 5: Build Collector Protocols and Fakes

**Files:**
- Create: `MacStatsBar/Services/Collectors/StatsCollecting.swift`
- Create: `MacStatsBar/Services/Collectors/FakeStatsCollector.swift`
- Test: `MacStatsBarTests/StatsCollectorProtocolTests.swift`

**Step 1: Write failing protocol-driven tests**

```swift
func testFakeCollectorReturnsInjectedSnapshot() async throws {
    let expected = StatsSnapshot.sample()
    let collector = FakeStatsCollector(snapshot: expected)
    let actual = try await collector.collect()
    XCTAssertEqual(actual, expected)
}
```

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/StatsCollectorProtocolTests`
Expected: FAIL.

**Step 3: Implement protocol + fake**

Define `protocol StatsCollecting { func collect() async throws -> StatsSnapshot }`.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/Services/Collectors MacStatsBarTests/StatsCollectorProtocolTests.swift
git commit -m "feat: add stats collector abstraction and fake"
```

### Task 6: Implement Stats Store Scheduler

**Files:**
- Create: `MacStatsBar/Services/StatsStore.swift`
- Test: `MacStatsBarTests/StatsStoreTests.swift`

**Step 1: Write failing store tests**

```swift
func testRefreshPublishesSnapshot() async throws {
    let expected = StatsSnapshot.sample()
    let store = StatsStore(collector: FakeStatsCollector(snapshot: expected), refreshInterval: 2)
    try await store.refreshOnce()
    XCTAssertEqual(store.currentSnapshot, expected)
}
```

Add tests for error fallback (placeholders, no crash) and network delta calculation across snapshots.

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/StatsStoreTests`
Expected: FAIL.

**Step 3: Implement `StatsStore`**

Use `@MainActor` + `ObservableObject`, publish `currentSnapshot`, and support manual `refreshOnce()` plus timer start/stop.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/Services/StatsStore.swift MacStatsBarTests/StatsStoreTests.swift
git commit -m "feat: add polling stats store with publish pipeline"
```

### Task 7: Implement System Metric Collectors (No Extra Permissions)

**Files:**
- Create: `MacStatsBar/Services/Collectors/System/SystemStatsCollector.swift`
- Create: `MacStatsBar/Services/Collectors/System/CPUCollector.swift`
- Create: `MacStatsBar/Services/Collectors/System/MemoryCollector.swift`
- Create: `MacStatsBar/Services/Collectors/System/NetworkCollector.swift`
- Create: `MacStatsBar/Services/Collectors/System/BatteryCollector.swift`
- Create: `MacStatsBar/Services/Collectors/System/DiskCollector.swift`
- Test: `MacStatsBarTests/SystemCollectorMappingTests.swift`

**Step 1: Write failing mapping tests**

```swift
func testUnavailableMetricMapsToNilAndDoesNotThrow() async throws {
    let collector = SystemStatsCollector(cpu: .failing, memory: .stub, network: .stub, battery: .stub, disk: .stub)
    let snapshot = try await collector.collect()
    XCTAssertNil(snapshot.cpu)
    XCTAssertNotNil(snapshot.memory)
}
```

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/SystemCollectorMappingTests`
Expected: FAIL.

**Step 3: Implement collectors**

- CPU: host processor load info.
- Memory: VM statistics + physical memory.
- Network: interface byte counters (`getifaddrs` + deltas in store).
- Battery: `IOPSCopyPowerSourcesInfo`.
- Disk: filesystem capacity via `URLResourceValues`.

All collectors must return optional fields without throwing for partial failures.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/Services/Collectors/System MacStatsBarTests/SystemCollectorMappingTests.swift
git commit -m "feat: add system collectors for cpu memory network battery disk"
```

### Task 8: Render Menu Bar Summary (Configurable, Max 2)

**Files:**
- Modify: `MacStatsBar/MenuBar/StatusBarController.swift`
- Create: `MacStatsBar/MenuBar/SummarySelectionEngine.swift`
- Test: `MacStatsBarTests/SummarySelectionEngineTests.swift`

**Step 1: Write failing selection tests**

```swift
func testSelectionLimitsToTwoByDefault() {
    let order: [MetricKind] = [.cpuUsage, .memoryUsage, .networkThroughput]
    let shown = SummarySelectionEngine.visibleMetrics(order: order, maxVisible: 2)
    XCTAssertEqual(shown, [.cpuUsage, .memoryUsage])
}
```

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/SummarySelectionEngineTests`
Expected: FAIL.

**Step 3: Implement summary selection + status updates**

Bind `StatsStore` + `PreferencesStore` output to `statusItem.button?.title`.

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/MenuBar/StatusBarController.swift MacStatsBar/MenuBar/SummarySelectionEngine.swift MacStatsBarTests/SummarySelectionEngineTests.swift
git commit -m "feat: render configurable menu bar summary with max-two auto-fit"
```

### Task 9: Build Popover Detail UI and Settings

**Files:**
- Create: `MacStatsBar/UI/PopoverRootView.swift`
- Create: `MacStatsBar/UI/MetricCards/*.swift`
- Create: `MacStatsBar/UI/SettingsView.swift`
- Create: `MacStatsBar/UI/ViewModels/PopoverViewModel.swift`
- Test: `MacStatsBarTests/PopoverViewModelTests.swift`

**Step 1: Write failing view-model tests**

```swift
func testPopoverViewModelBuildsAllCoreCards() {
    let vm = PopoverViewModel(snapshot: .sample())
    XCTAssertEqual(vm.cards.count, 5)
}
```

Add tests for placeholder rendering on nil metrics.

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/PopoverViewModelTests`
Expected: FAIL.

**Step 3: Implement popover and settings**

Create SwiftUI card views for CPU, memory, network, battery, disk and settings controls (summary order, interval, launch-at-login toggle, popover pin behavior).

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/UI MacStatsBarTests/PopoverViewModelTests.swift
git commit -m "feat: add popover detail views and settings panel"
```

### Task 10: Launch-at-Login + App Lifecycle Hardening

**Files:**
- Create: `MacStatsBar/Services/LoginItemService.swift`
- Modify: `MacStatsBar/App/AppDelegate.swift`
- Test: `MacStatsBarTests/LoginItemServiceTests.swift`
- Test: `MacStatsBarTests/LifecycleResilienceTests.swift`

**Step 1: Write failing service/lifecycle tests**

```swift
func testLifecyclePauseAndResumePolling() async throws {
    let store = StatsStore(collector: FakeStatsCollector(snapshot: .sample()), refreshInterval: 1)
    store.handleWillSleep()
    XCTAssertFalse(store.isPolling)
    store.handleDidWake()
    XCTAssertTrue(store.isPolling)
}
```

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS' -only-testing:MacStatsBarTests/LoginItemServiceTests -only-testing:MacStatsBarTests/LifecycleResilienceTests`
Expected: FAIL.

**Step 3: Implement minimal lifecycle integrations**

Wire sleep/wake notifications and login item registration facade (mockable in tests).

**Step 4: Run tests to verify pass**

Run same command.
Expected: PASS.

**Step 5: Commit**

```bash
git add MacStatsBar/Services/LoginItemService.swift MacStatsBar/App/AppDelegate.swift MacStatsBarTests/LoginItemServiceTests.swift MacStatsBarTests/LifecycleResilienceTests.swift
git commit -m "feat: add launch-at-login and lifecycle resilience handling"
```

### Task 11: End-to-End Verification and Docs

**Files:**
- Modify: `README.md`
- Modify: `progress.md`
- Create: `docs/testing/manual-test-checklist.md`

**Step 1: Write failing docs checklist tests (lint-style)**

Add a simple docs verification script or checklist validation if available; otherwise treat missing checklist file as fail in CI script.

**Step 2: Run verification to confirm fail**

Run: `test -f docs/testing/manual-test-checklist.md`
Expected: non-zero exit code before file creation.

**Step 3: Add docs and verification notes**

Document:
- Build/run steps
- What “no extra permissions” means in practice
- Manual checks for sleep/wake, network changes, battery transitions

**Step 4: Run full verification**

Run:
- `xcodebuild test -scheme MacStatsBar -destination 'platform=macOS'`
- `xcodebuild build -scheme MacStatsBar -destination 'platform=macOS'`

Expected: all tests pass, build succeeds.

**Step 5: Commit**

```bash
git add README.md progress.md docs/testing/manual-test-checklist.md
git commit -m "docs: add runbook and release verification checklist"
```

## Implementation Notes

- Keep each commit focused on one task.
- Prefer protocol boundaries around OS calls for testability.
- Do not add deferred metrics (thermal/fan/GPU/per-process) in v1 branch.
- If any command/path differs after scaffolding, update this plan in-place before continuing.

