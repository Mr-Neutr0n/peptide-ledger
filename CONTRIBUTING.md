# Contributing

## Setup

Xcode 26, Swift 6, and XcodeGen. macOS 15 or newer for `swift test`.

```sh
brew install xcodegen
./verify
```

`verify` is `swift build`, then `swift test`, then `xcodegen generate`, then
`xcodebuild` for the iOS Simulator. It must fail on the first red stage.

## Tests

Package logic lives in `Sources/` and is covered by Swift Testing under
`Tests/`. Eval fixtures in `eval/` run through `MockProvider`; they must
not call a live API in CI.

Synthetic data only. No real vial photos, lot numbers from a real pharmacy,
or identified health notes in issues, fixtures, or screenshots.

## Product rules that are not optional

- No dosing advice, protocol generators, or compound "recommended dose"
  libraries.
- Arithmetic stays in `DoseMath`. The model extracts numbers; it does not
  convert them.
- Ledger writes happen only after the user confirms. History is append-only.
- No analytics, no backend, no vendor/sourcing copy.

## Commits

Sign off each commit (`git commit -s`) so the Apache-2.0 patent grant rides
the contribution. Use short, plain messages. Do not add an AI as a
co-author.

Open an issue before adding a network host other than the user-chosen
model endpoint.
