# NEXT

Handoff as of 8 Sep 2026. Check git and `./verify` before trusting this
file.

## State

- Package libraries and Swift Testing suites exist under `Sources/` and
  `Tests/`.
- iOS shell: lock, onboarding, capture, ledger, vials, reconstitution
  tool, export, settings.
- Eval: 25 rambles, 10 synthetic label texts, mock-provider tests.
- Docs listed in the README are real files, not stubs.

## Known gaps

- This laptop had iOS Simulator SDK 26.5 but no installed simulator
  runtime (`xcrun simctl list runtimes` was empty). `./verify` therefore
  runs `xcodebuild -target PeptideLedger -sdk iphonesimulator -arch arm64`
  which compiles and links the app (`BUILD SUCCEEDED`) without booting a
  simulator. Install an iPhone 17 runtime to run the UI. A full
  `xcodebuild -downloadPlatform iOS` is an 8.5 GB fetch; it was started
  and then stopped once the SDK build passed.
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
