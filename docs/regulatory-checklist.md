# Four-criteria checklist (FDA CDS guidance, January 2026)

Intended-use statement: `docs/intended-use.md`.
Guidance: https://www.fda.gov/regulatory-information/search-fda-guidance-documents/clinical-decision-support-software

Criterion 1: no images, IVD signals, or signal-acquisition patterns used
as medical images. Vial-label photos are photographs of packaging the
user already has; Vision runs on-device to recover printed text.
Criterion 2: displays or analyzes medical information the user supplied.
Criterion 3: records and conversions, not directives; no patient-specific
scores, no protocol generator.
Criterion 4: the user can independently review the basis.

| Surface | C1 | C2 | C3 | C4 | Notes |
|---|---|---|---|---|---|
| `propose_events` | text / label text in | extracts user-stated facts | proposal plus gap list, no dose advice | excerpt per row; unconfirmed | clerk prompt forbids prescribing |
| `commit_events` | n/a | writes confirmed rows | user taps accept | JSONL is the inspectable log | never auto-commits |
| `reconstitute` / `draw_volume` | numbers the user typed | unit conversion | flags insane results, does not suggest a dose | formula and every input shown | pure Swift, no model math |
| Label OCR | packaging photo, not a body image | candidate fields | never auto-files | raw text kept with the candidate | user confirms |
| Timeline / vials | local projection | displays the log | no recommendation | rebuildable from JSONL | append-only |
| Export | file out | user-owned archive | n/a | JSONL + CSV | share sheet only |
| Lock / onboarding | n/a | n/a | 17+ disclaimer | disclaimer text is in-app and in-repo | Face ID / passcode |

Time-critical use is out of scope. The persona declines "what should I
take" framings (eval fixture R12).

No surface in this release relies on FDA's enforcement-discretion clause
for software whose single output is the only clinically appropriate
option. Informational, non-directive outputs stay on the lowest risk
tier by construction: drafts are never directives.

## App Store

- Guideline 1.4.1: no accuracy claim about a sensor measurement. DoseMath
  converts typed numbers and shows the formula. OCR is labeled as a
  candidate.
- Guideline 5.1.1: no account, no collected data types in the privacy
  manifest, key in Keychain, ledger on device.
- Guideline 5.1.3: we do not use HealthKit in this release. Health-ish
  text the user types stays on the phone except for the model call they
  start. Age rating 17+ (frequent medical / treatment information in the
  questionnaire; override if the calculated rating is lower).
- Declare regulated medical device: No, in the US, UK, and EU/EEA.

This is a self-map, not a legal opinion and not an FDA submission.
