# Decisions

Calls made while scaffolding v0. Review these if they age badly.

## JSONL event log, not SwiftData, is the ledger

The source of truth is `ledger.jsonl` on disk, rebuilt into a projection
in memory. Reasons: the ledger is append-only events (SwiftData rows invite
in-place edits); `swift test` on macOS does not need a simulator; the
export artifact is the store. Familiar uses SwiftData for chat; our
record is closer to a log. SwiftData remains available later for
projections if iPhone UI needs `@Query`. Recorded 8 Sep 2026.

## XcodeGen plus a Swift package, not Tuist, not a hand-edited pbxproj

Logic is SPM libraries. The iOS target is a thin XcodeGen spec so the
project is reviewable in git without merging a 4k-line pbxproj by hand.
Tuist is the better large-team tool (Swift manifests, cache). This repo
is one app and five libraries. XcodeGen 2.46 is enough. Recorded 8 Sep 2026.

## Swift Testing for packages; XCTest for the UI smoke test

Swift Testing is the 2026 default for unit tests (`@Test`, `#expect`).
XCTest remains required for UI tests, so `PeptideLedgerUITests` is XCTest.
Recorded 8 Sep 2026.

## `--ui-test-mock` is a Debug-only seam, not a feature flag

The UI test needs a deterministic provider and must not touch Keychain or
the real ledger. `AppState` reads the launch argument only under `#if
DEBUG`, swaps in `MockProvider` with the R01 fixture answer, uses a
temporary ledger directory, and skips the lock screen because
LocalAuthentication is system UI that XCUITest cannot drive. Release
builds ignore the argument. Recorded 8 Sep 2026.

## Filing rows never depends on the model provider

`Clerk.commit` is static. A cleared or invalid API key must not block
confirming rows that were already proposed. Recorded 8 Sep 2026.

## Public GitHub repo for the app, private repo for the site

The app is Apache-2.0 source. The placeholder name is awkward but does
not collide with Pep. The marketing site stays private until the name is
real. Recorded 8 Sep 2026.

## Display name "Peptide Ledger"

Working title only. Bundle id `dev.neutr0n.peptideledger`. Do not ship
App Store copy that looks like Pep. Recorded 8 Sep 2026.

## Providers: Anthropic Messages plus OpenAI-compatible

Covers OpenAI, OpenRouter, and local servers. No first-party proxy. The
user types the base URL. Recorded 8 Sep 2026.

## IU conversion refuses without a user-supplied factor

IU is potency. A hidden default factor would be dosing advice by another
name. Recorded 8 Sep 2026.

## Compaction is stubbed

Session trees can grow. pi-style compaction is a hook with a message, not
an implementation. Ledger events are never compacted. Recorded 8 Sep 2026.

## `verify` adapts to whether a simulator runtime exists

With an iPhone runtime installed, `verify` builds and runs the UI smoke
test on it. Without one (fresh CI image, laptop before the 8.5 GB
download), it builds the app against the simulator SDK only and says so.
Both paths fail on the first broken stage. Recorded 8 Sep 2026.
