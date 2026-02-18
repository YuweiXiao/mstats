# Progress Tracker

Date started: 2026-02-18

## Current Phase
- [x] PRD drafted and validated
- [x] Implementation plan drafted (`docs/plans/2026-02-18-macstats-bar-implementation-plan.md`)
- [x] Architecture spike
- [x] MVP implementation (core services + UI components)
- [ ] QA and release prep

## v1 Scope (Committed)
- [x] Local Mac monitoring only
- [x] Menu bar summary configurable (up to 2 items shown by default)
- [x] Core metrics: CPU, memory, network, battery, disk
- [ ] Click popover with detailed metrics (UI implemented; click-to-open integration pending)
- [x] No extra permissions
- [x] macOS 14+

## Deferred Metrics / Features (Post-v1)
- [ ] Temperature metrics
- [ ] Fan speed metrics
- [ ] GPU metrics
- [ ] Per-process stats
- [ ] Historical mini-charts (advanced)
- [ ] Remote machine monitoring

## Notes
- This file tracks TODO and progress for product scope decisions.
- Deferred items should move into milestones only after v1 stability targets are met.
- Remaining gap before release: wire menu bar click to popover presentation and complete manual checklist in `docs/testing/manual-test-checklist.md`.
