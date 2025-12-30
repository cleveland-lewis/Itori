# Auto-Reschedule Invariant Hardening

## Core Invariant
If `enableAutoReschedule == false` then:
- No timers run
- No missed-session checks execute
- No planner mutations occur
- No history entries are written
- No notifications are scheduled

## Single Gate
All auto-reschedule execution must pass through `AutoRescheduleGate.run(...)` or `AutoRescheduleGate.shouldAllow(...)`.
This is the only allowed entry point for timers, checks, strategy execution, mutations, and notifications.

## DEBUG Canaries
The following methods assert in DEBUG if they run while disabled:
- `MissedEventDetectionService.checkForMissedSessions`
- `AutoRescheduleEngine.rescheduleSession`
- `AutoRescheduleEngine.applyRescheduleOperations`
- `AutoRescheduleEngine.notifyUserOfReschedule`
- `AutoRescheduleEngine.saveHistory`

These are compiled out in RELEASE.

## Activity Counters (Dev Only)
`AutoRescheduleActivityCounter` tracks:
- Checks executed
- Sessions analyzed
- Sessions moved
- History entries written
- Notifications scheduled
- Suppressed executions

Use the Developer Settings panel: “Auto-Reschedule Counters”.
When disabled, all counters except “Suppressed” must remain zero.

## Audit Log
`AutoRescheduleAuditLog` records executed and suppressed batches:
- Reason (timer/manual/etc.)
- Provenance (automatic/user)
- Status (executed/suppressed/failed)
- Strategy summary (sameDay/pushed/nextDay/overflow)

Suppressed entries are recorded explicitly, never silently.

## CI Enforcement
`PlannerSafetyNetTests` includes:
- Disabled invariant test (no mutations, no notifications)
- Concurrency stress test (multiple triggers)

CI must fail if any activity counter increments while disabled.

## DO NOT SHIP IF…
- Auto-reschedule disabled yet any non-suppressed counters > 0
- Planner mutations or notifications occur while disabled
- DEBUG canaries fire in normal flows

## Adding New Strategies Safely
1) Implement strategy in `AutoRescheduleEngine` only.
2) Ensure all entry points pass through `AutoRescheduleGate`.
3) Add DEBUG canary in strategy path.
4) Update activity counters if new behavior mutates planner or schedules notifications.
5) Add tests that prove disabled => no side effects.
