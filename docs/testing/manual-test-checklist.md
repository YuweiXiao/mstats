# Manual Test Checklist

Date: 2026-02-18

## Environment

- macOS 14+ machine
- App built from current `feature/macstats-v1` branch

## Smoke

- [ ] App launches without crash.
- [ ] Menu bar item appears with summary text.
- [ ] Summary updates over time (no frozen values).

## Summary Behavior

- [ ] Default summary shows up to 2 metrics.
- [ ] Summary order changes when preferences order changes.
- [ ] Missing metric values render placeholders (`--`) not crashes.

## Popover

- [ ] Clicking menu bar item opens popover.
- [ ] Popover shows 5 cards (CPU/Memory/Network/Battery/Disk).
- [ ] Card values show placeholders when data unavailable.
- [ ] Settings controls are interactive (summary order, refresh interval, launch at login, popover mode).

## Lifecycle And Stability

- [ ] App survives sleep/wake cycle.
- [ ] Polling pauses on sleep and resumes on wake when expected.
- [ ] Explicit stop behavior does not auto-resume incorrectly on wake.
- [ ] Network reset/rollback does not show bogus huge throughput spikes.

## Settings And Persistence

- [ ] Changing preferences persists across relaunch.
- [ ] Login-at-startup toggle updates backend state correctly.
- [ ] Re-applying same login setting is idempotent (no errors).

## Resource/Robustness

- [ ] App remains responsive while running for 10+ minutes.
- [ ] No repeated crash loops on temporary metric collection failures.

