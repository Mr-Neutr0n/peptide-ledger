# Security policy

## Reporting a vulnerability

Do not open a public GitHub issue for a security report.

Use GitHub private vulnerability reporting on this repository (Security tab,
"Report a vulnerability"). If that form is unavailable, email the maintainer
through the GitHub profile listed on the repo.

You should hear an acknowledgment within 48 hours and a status update within
7 days. Coordinated disclosure follows a fix, or 90 days, whichever is sooner.

## Supported versions

Only the latest published 0.x source on `main` is supported until a 1.0 line
exists.

## What this app can reach

There is no company server. The iOS app:

- Stores the ledger and sessions as JSONL under the app's Application Support
  directory on the phone.
- Stores the model API key in the iOS Keychain
  (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
- Makes HTTPS requests only to the model host the user configured (Anthropic
  Messages, or an OpenAI-compatible chat-completions URL they typed).
- Does not include analytics SDKs, crash reporters, or advertising kits.
- Does not log the API key. `ModelClient` redacts supplied secrets before any
  log sink sees a string.

The user's chosen model provider receives whatever ramble, OCR text, and
ledger summary they send when they tap Propose. That is their egress, not
ours.

## Health data

This repository distributes source code. The maintainers never receive
health data. Anyone who sideloads or ships a build is responsible for
their own HIPAA / GDPR posture, including the model provider they point
the app at.

This is a scope clarification, not legal advice.
