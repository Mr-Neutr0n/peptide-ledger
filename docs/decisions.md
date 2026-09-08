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

## Swift Testing for packages; XCTest only if we add UI tests

Swift Testing is the 2026 default for unit tests (`@Test`, `#expect`).
XCTest remains required for UI tests. v0 has no UI test target. Recorded
8 Sep 2026.

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

## Simulator runtime may be missing on this laptop

The SDK `iphonesimulator26.5` is installed. `simctl list runtimes` was
empty on the build machine, so `verify` uses a generic iOS Simulator
destination when no iPhone device exists. Recorded 8 Sep 2026.
