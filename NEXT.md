# NEXT

Handoff as of 8 Sep 2026. Check git and `./verify` before trusting this
file.

## State

- Package libraries and Swift Testing suites exist under `Sources/` and
  `Tests/`.
- iOS shell: lock, onboarding, capture, ledger, vials, reconstitution
  tool, export, settings.
- Eval: 25 rambles, 10 synthetic label texts, mock-provider tests.
- UI smoke test `UITests/CaptureFlowUITests.swift` runs on a booted iPhone
  17 Pro (iOS 26.5 runtime installed 8 Sep 2026): onboarding gate,
  ramble, proposal card with gap list, confirm, row visible in Ledger.
  It launches the app with `--ui-test-mock` (Debug only): canned
  `MockProvider` answer matching eval fixture R01, throwaway ledger dir,
  Keychain skipped, lock skipped because LocalAuthentication is system UI.
- `./verify` runs that UI test when an iPhone runtime exists, otherwise
  falls back to an SDK-only build. Last full run: 31 unit tests, UI test
  passed in 20 s, `verify passed`.
- Docs listed in the README are real files, not stubs.

## Known gaps

- Only one UI test. Vials, Tools, Export, and Settings screens compile
  and render but have no automated drive-through yet.
- Speech dictation and Vision OCR are not exercised by the UI test (no
  mic or photo library in the mock path). Needs a real device pass.
- Session JSONL date encoding is ISO-8601 on write; older default-encoded
  lines still decode.
- Photo bytes are OCR'd; attaching the image file to a vial row is a
  `noteAdded` path, not a first-class photo store.
- Streaming tokens are implemented on the providers but Capture waits on
  `complete` for the JSON proposal.
- No Watch app, no PK curve, no clinician PDF, no iCloud, no Android.
- Compaction is a stub (see `SessionStore.compact`).
- If the device has no passcode, the lock screen currently unlocks. That
  should become a hard fail before App Store.

## Follow-ups worth doing, not in this commit

- Labeled PK estimates from published half-lives, never called serum
  levels, never used to tell someone to take more.
- Clinician-filtered PDF export (separate from the full archive).
- User-supplied cited compound cards.
- Real device pass on Speech + Vision + Keychain.
- Manual row editor that still writes a supersede event rather than
  mutating history.
