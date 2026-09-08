# Permissions and data

There is no company backend. This page lists every permission, every
network call, and what sits on the phone.

## On the phone

| Location | Contents |
|---|---|
| Application Support `/peptide-ledger/ledger.jsonl` | Append-only ledger events |
| Application Support `/peptide-ledger/sessions.jsonl` | Clerk session tree (`id`, `parentId`) |
| Application Support `/peptide-ledger/photos/` | Optional vial photos (v0 may only keep OCR text) |
| Keychain service `dev.neutr0n.peptideledger` | Model API key, `WhenUnlockedThisDeviceOnly` |
| UserDefaults | Onboarding flags, provider kind, model id, base URL (not the key) |

Face ID / passcode uses `LocalAuthentication` policy
`deviceOwnerAuthentication`. If the device has no passcode, the lock
screen currently lets the user through. That is a documented gap.

## Network

The only intended egress is the model host the user configured.

| Host | When | What is sent |
|---|---|---|
| `api.anthropic.com` (default Anthropic) | User taps Propose | system prompt, ramble, optional OCR text, ledger summary |
| User-typed OpenAI-compatible base URL | User taps Propose | same, as chat completions |

No other host is hard-coded. There is no analytics, crash reporter,
update ping, or account API.

Speech recognition may use Apple's on-device engine. If the system falls
back to Apple's servers, that is an Apple path, not ours; the usage
string says the transcript stays on the phone until the user sends a
proposal.

## Secrets

The API key never goes into JSONL, UserDefaults, or logs. `Redaction`
replaces any supplied secret with `<redacted-key>` before a log sink
runs. HTTP error bodies are redacted the same way.

## What the app never does

- No account, no cloud sync, no iCloud store in this release.
- No HealthKit read or write.
- No vendor names, sourcing, or "where to buy."
- No third-party SDK that phones home.
