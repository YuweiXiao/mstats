# CPU Plot Visualization Optimization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve the CPU plot so it is visually trustworthy and readable while keeping the top-process panel stable and non-disruptive to layout.

**Architecture:** Introduce CPU-specific sparkline styling (fixed 0-100 domain, safer interpolation, larger plot area) and move the current ad-hoc CPU row layout into a dedicated composite CPU card view. Keep process list rendering in a fixed-size side panel that can be empty without changing chart width.

**Tech Stack:** SwiftUI, Charts, XCTest, SwiftPM, AppKit `NSPopover`

---

### Task 1: Define CPU Plot Visual Rules in a Testable Style Model

**Files:**
- Create: `Sources/MacStatsBar/UI/MetricCards/MetricSparklineStyle.swift`
- Modify: `Sources/MacStatsBar/UI/MetricCards/MetricCardView.swift`
- Test: `Tests/MacStatsBarTests/MetricSparklineDataBuilderTests.swift`

**Step 1: Write the failing test**

Add tests for a new style provider API to assert CPU-specific visualization rules:
- fixed Y domain `0...100`
- non-overshooting interpolation (recommend `.monotone` or `.linear`)
- taller plot height than default cards
- optional grid/reference lines enabled for CPU only

Example test skeleton:
```swift
func testCPUCardUsesFixedPercentDomainAndStableInterpolation() {
    let style = MetricSparklineStyle.style(for: .cpuUsage)

    XCTAssertEqual(style.yDomain?.lowerBound, 0)
    XCTAssertEqual(style.yDomain?.upperBound, 100)
    XCTAssertEqual(style.interpolation, .monotone)
    XCTAssertGreaterThan(style.height, 34)
}
```

**Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter MetricSparklineDataBuilderTests`
Expected: FAIL (missing `MetricSparklineStyle` and style provider)

**Step 3: Write minimal implementation**

Create a small style type and a `style(for:)` factory keyed by `MetricKind`.
Keep all non-CPU metrics using current defaults.

**Step 4: Run test to verify it passes**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter MetricSparklineDataBuilderTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacStatsBar/UI/MetricCards/MetricSparklineStyle.swift Sources/MacStatsBar/UI/MetricCards/MetricCardView.swift Tests/MacStatsBarTests/MetricSparklineDataBuilderTests.swift
git commit -m "feat: add configurable sparkline styles"
```

### Task 2: Apply Visualization-Safe CPU Plot Rendering in `MetricCardView`

**Files:**
- Modify: `Sources/MacStatsBar/UI/MetricCards/MetricCardView.swift`
- Modify: `Sources/MacStatsBar/UI/MetricCards/CPUCardView.swift`
- Test: `Tests/MacStatsBarTests/PopoverViewModelTests.swift` (compile/behavior regression coverage only)

**Step 1: Write the failing test**

Add a small CPU card construction regression test if practical (or expand an existing compile-level view instantiation test) to ensure CPU card still renders when style is applied.

**Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter PopoverViewModelTests`
Expected: FAIL after introducing new required style parameters (temporary)

**Step 3: Write minimal implementation**

Update `MetricSparklineView` to consume style options:
- `chartYScale(domain:)` when provided
- CPU interpolation mode from style
- subtle rule marks/grid cues (0/50/100) only when style requests it
- optional area fill under line for CPU (light alpha, same hue)

CPU should use the style provider; other cards continue default behavior.

**Step 4: Run test to verify it passes**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter PopoverViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacStatsBar/UI/MetricCards/MetricCardView.swift Sources/MacStatsBar/UI/MetricCards/CPUCardView.swift Tests/MacStatsBarTests/PopoverViewModelTests.swift
git commit -m "feat: improve cpu sparkline visualization"
```

### Task 3: Replace Ad-hoc CPU Row With Dedicated Composite CPU Card Layout

**Files:**
- Create: `Sources/MacStatsBar/UI/MetricCards/CPUCompositeCardView.swift`
- Modify: `Sources/MacStatsBar/UI/PopoverRootView.swift`
- Optional Modify: `Sources/MacStatsBar/UI/ViewModels/PopoverViewModel.swift` (only if a dedicated CPU panel VM struct is introduced)
- Test: `Tests/MacStatsBarTests/PopoverViewModelTests.swift`

**Step 1: Write the failing test**

Add a `PopoverRootView` construction test covering empty and non-empty process panels (can remain compile/instantiation-level if no snapshot framework exists).

Example:
```swift
func testPopoverRootViewAcceptsSnapshotWithNoTopCPUProcesses() {
    let snapshot = StatsSnapshot(timestamp: .now, metrics: [.cpuUsage: ...], processCPUUsages: [])
    let view = PopoverRootView(snapshot: snapshot, settings: .constant(.defaultValue))
    XCTAssertNotNil(view)
}
```

**Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter PopoverViewModelTests`
Expected: FAIL after wiring `PopoverRootView` to new composite view API (temporary)

**Step 3: Write minimal implementation**

Create `CPUCompositeCardView` that contains:
- left: CPU metric title/value + improved plot
- right: fixed-height/fixed-width top-process panel
- empty panel state = blank content (no label text beyond section title)
- consistent heights so no layout jump when process list is empty

Update `PopoverRootView` to use `CPUCompositeCardView` for `.cpuUsage` instead of custom row logic. This removes CPU-specific layout branching from `PopoverRootView` and centralizes CPU UX in one component.

**Step 4: Run test to verify it passes**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter PopoverViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacStatsBar/UI/MetricCards/CPUCompositeCardView.swift Sources/MacStatsBar/UI/PopoverRootView.swift Tests/MacStatsBarTests/PopoverViewModelTests.swift
git commit -m "refactor: move cpu process panel into composite cpu card"
```

### Task 4: Tune CPU Plot for Visual Readability (Spacing, Labels, Domain Behavior)

**Files:**
- Modify: `Sources/MacStatsBar/UI/MetricCards/CPUCompositeCardView.swift`
- Modify: `Sources/MacStatsBar/UI/MetricCards/MetricCardView.swift`
- Test: `Tests/MacStatsBarTests/MetricSparklineDataBuilderTests.swift`

**Step 1: Write the failing test**

Add tests for CPU style details if extracted (e.g., fixed tick set `[0, 50, 100]`, area fill enabled).

**Step 2: Run test to verify it fails**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter MetricSparklineDataBuilderTests`
Expected: FAIL for new style expectations

**Step 3: Write minimal implementation**

Tune without changing data semantics:
- maintain fixed 0-100 domain
- ensure chart line stroke width remains readable at current panel width
- reduce clutter (hide axes labels, keep only faint reference rules)
- prevent interpolation overshoot (prefer `.monotone` or `.linear`)
- preserve monospaced current value text alignment

**Step 4: Run test to verify it passes**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter MetricSparklineDataBuilderTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacStatsBar/UI/MetricCards/CPUCompositeCardView.swift Sources/MacStatsBar/UI/MetricCards/MetricCardView.swift Tests/MacStatsBarTests/MetricSparklineDataBuilderTests.swift
git commit -m "feat: tune cpu plot readability and scale cues"
```

### Task 5: Full Verification and Bundle Build

**Files:**
- No code changes expected (verification only)

**Step 1: Run targeted tests**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter 'PopoverViewModelTests|MetricSparklineDataBuilderTests|SystemCollectorMappingTests|SummarySelectionEngineTests'`
Expected: PASS

**Step 2: Run broader suite (recommended)**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`
Expected: PASS

**Step 3: Build app bundle (required after major UI changes)**

Run: `./scripts/build_app_bundle.sh`
Expected: `dist/mstats.app` generated successfully

**Step 4: Manual UX verification checklist**

- CPU chart width does not change when no process is >= 1%
- CPU chart remains readable with 10 processes shown
- Top-process panel can be empty without layout jump
- CPU chart uses fixed percent scale (0-100) and no misleading spikes from interpolation overshoot
- Popover still fits target screens without internal scrolling (or fails gracefully if display height is constrained)

**Step 5: Commit final polish**

```bash
git add -A
git commit -m "feat: optimize cpu plot visualization layout"
```
