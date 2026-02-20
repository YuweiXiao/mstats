# Progress Tracker

Date started: 2026-02-18

## Current Phase
- [x] PRD drafted and validated
- [x] Implementation plan drafted (`docs/plans/2026-02-18-macstats-bar-implementation-plan.md`)
- [x] Architecture spike
- [x] MVP implementation (core services + UI components)
- [x] QA and release prep (automated suite + bundle build workflow)

## v1 Scope (Committed)
- [x] Local Mac monitoring only
- [x] Menu bar summary configurable (up to 2 items shown by default)
- [x] Core metrics: CPU, memory, network, battery, disk
- [x] Click popover with detailed metrics
- [x] No extra permissions
- [x] macOS 14+

## Deferred Metrics / Features (Post-v1)
- [ ] Temperature metrics
- [ ] Fan speed metrics
- [ ] GPU metrics
- [ ] Per-process stats
- [ ] Historical mini-charts (advanced)
- [ ] Remote machine monitoring

## Active TODO
- [x] Replace menu bar network rendering with true 2-line status-item view path.
- [x] Expand 2-line network behavior to all summary combinations (network-only and network+one additional metric).
- [x] Restore popover click handling after switching from multiline network view back to single-line CPU-only view.
- [ ] Validate on-device that menu bar shows network download on line 1 and upload on line 2 across all selected summary combinations after rebuild/relaunch.

## Notes
- This file tracks TODO and progress for product scope decisions.
- Deferred items should move into milestones only after v1 stability targets are met.
- App bundle workflow now available via `scripts/build_app_bundle.sh` (outputs `dist/mstats.app`).
- Manual checklist remains for interactive QA sign-off in `docs/testing/manual-test-checklist.md`.
- App Store packaging foundation added via `project.yml` + `MacStatsBar.xcodeproj` + `AppStore/` metadata/entitlements.
