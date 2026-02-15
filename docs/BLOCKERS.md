# BauHouse — Blockers

> Blockers are logged here when the agent encounters an issue requiring owner input.
> Format: [BLOCKER-ID] with Raised, Task affected, Description, Information needed, Impact, Status.

## BLOCKER-001

| Field | Details |
|-------|---------|
| **Raised** | 2026-02-15 |
| **Task** | P0-11 — Phase 0 PR and TestFlight build |
| **Description** | TestFlight build requires Apple Developer account credentials, provisioning profiles, App Store Connect configuration, and Xcode code signing. These are not available to the agent. |
| **Information needed** | 1) Apple Developer Team ID, 2) Bundle identifier confirmation (com.bauhouse.app or similar), 3) Provisioning profile setup, 4) App Store Connect app record |
| **Impact** | Cannot produce TestFlight build. All other Phase 0 work is complete. The PR with all code changes can be created and merged. |
| **Status** | OPEN — Awaiting owner |

## BLOCKER-002

| Field | Details |
|-------|---------|
| **Raised** | 2026-02-15 |
| **Task** | P0-01 — Repository & project setup |
| **Description** | Font files (DM Sans) referenced in pubspec.yaml are not yet sourced. The fonts section is currently commented out. |
| **Information needed** | Confirm Google Fonts download, or switch to `google_fonts` package for runtime loading. |
| **Impact** | App renders with system default font instead of DM Sans. Cosmetic only; no functional impact. |
| **Status** | RESOLVED — 2026-02-15. DM Sans variable font sourced from Google Fonts GitHub repo. |
