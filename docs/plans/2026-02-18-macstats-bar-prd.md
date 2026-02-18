# MacStats Bar PRD (v1)

Date: 2026-02-18  
Status: Draft (validated with stakeholder)

## 1. Product Definition

### Working Name
MacStats Bar

### Platform
macOS 14+ (Sonoma and newer)

### Problem
Users currently switch between Activity Monitor, terminal commands, and multiple utilities to check system health. This creates workflow interruption for quick status checks.

### Target Users
- Developers
- Power users
- Creators and operators who want continuous machine visibility

### Product Goals
- Show live system stats directly in macOS menu bar.
- Let users configure what appears in menu bar summary.
- Show richer details in a click-open hover popover.
- Require no extra permissions in v1.
- Maintain low steady-state resource usage.

### Non-Goals (v1)
- Remote monitoring of other machines.
- GPU metrics, per-process deep inspection.
- Thermal/fan metrics.
- Advanced historical analytics dashboards.

### In-Scope Metrics (v1)
- CPU usage
- Memory usage
- Network throughput (up/down)
- Battery status
- Disk usage

### UX Posture
Balanced mode: menu bar summary and hover popover are both first-class.

## 2. Functional Requirements

### Menu Bar Summary
- App runs primarily as menu bar utility (no main app window required for normal use).
- Summary shows up to 2 metrics by default (`auto-fit up to 2`).
- User can choose summary metrics from: CPU, Memory, Network, Battery, Disk.
- If user selects more than 2 metrics, display top 2 by user-defined order.
- Optional metric rotation is deferred (not required in v1).
- Compact formats should be human-readable and stable, e.g.:
  - `CPU 23%`
  - `MEM 14.2/32 GB`
  - `NET 2.1↓ 0.4↑ MB/s`

### Hover Popover (on click)
- Click on menu bar item opens anchored popover.
- Popover shows all core metrics regardless of summary selection.
- Detail expectations:
  - CPU: total and per-core activity view.
  - Memory: used/free and pressure-like indicator.
  - Network: current up/down and short trend.
  - Battery: percent + charging/discharging state.
  - Disk: used/total + free space.

### Settings / Configuration
- Accessed from popover.
- Required controls:
  - Summary metric selection and order.
  - Refresh interval (1s / 2s / 5s).
  - Number/unit formatting.
  - Launch at login toggle.
  - Popover behavior (close on outside click, optional pin).

### Failure Behavior
- Missing metric values render placeholder (`--`) without crashing.
- Partial data availability must not block other metrics.
- No permission prompts beyond default app capabilities.

## 3. Technical Approach

### Suggested Stack
- Swift + SwiftUI native macOS app.
- `NSStatusItem`/menu bar integration + SwiftUI popover content.

### Architecture Components
- `StatsCollector`: gathers raw system stats.
- `StatsStore`: normalizes and publishes snapshot updates.
- `MenuBarRenderer`: renders compact selected metrics.
- `PopoverViewModel`: prepares detailed card/trend models.
- `PreferencesStore`: persists configuration via local storage.

### Data Flow
1. Timer ticks at configured interval (default 2s).
2. Collect raw counters/snapshots.
3. Compute derived values (e.g., network delta rate).
4. Publish UI models on main thread.
5. Render summary + popover views.

### Storage
- Local-only settings persistence.
- In-memory short ring buffer for recent trend display.
- No cloud sync in v1.

## 4. Do / Don't Constraints

### Do
- Keep always-on overhead low.
- Prioritize legibility in narrow menu bar space.
- Handle sleep/wake and network transitions gracefully.
- Keep all data local.

### Don’t
- Request Accessibility/Admin privileges in v1.
- Introduce remote telemetry by default.
- Overload menu bar with too many simultaneous elements.

## 5. Non-Functional Requirements

- Compatibility: macOS 14+
- Reliability: stable continuous run over long sessions.
- Performance target:
  - Low single-digit CPU when idle/light activity.
  - Modest memory footprint suitable for always-on utility.
- Privacy: no outbound data dependency required.
- Responsiveness: first visible summary appears quickly on launch.

## 6. Acceptance Criteria (v1)

- User can configure summary metrics and ordering.
- Menu bar renders and updates up to 2 selected metrics correctly.
- Popover opens from menu bar and displays all core metric details.
- Refresh rate and launch-at-login settings work as expected.
- App remains stable across:
  - Sleep/wake cycles
  - Network availability changes
  - Battery charge/discharge state changes

## 7. Deferred Scope

Deferred to post-v1 (tracked in `progress.md`):
- Thermal sensors (temperature/fan)
- GPU metrics
- Per-process metrics
- Advanced historical charts and exports
- Remote host monitoring

## 8. Milestones (suggested)

1. M1: Core collectors + summary rendering (CPU/MEM/NET/Battery/Disk)
2. M2: Popover detail cards + trend buffer
3. M3: Settings + persistence + launch at login
4. M4: Stability hardening + release checklist

