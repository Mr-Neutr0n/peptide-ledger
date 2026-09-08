# Intended use

Peptide Ledger is an on-device iOS app that helps a person file their own
injectable-peptide records. The user rambles (voice or text) and may attach
a photo of a vial they already have. The app proposes structured ledger
rows. Nothing is written until the user confirms.

It is software for personal record-keeping. It is not a medical device, not
a diagnostic service, not a dosing calculator that suggests what to take,
and not a substitute for a licensed clinician. The repository name is a
placeholder, not a brand clearance.

## Who it is for

Adults (17+) who already use injectable peptides or compounded GLP-1
preparations from vials and who want a local log: doses taken, vials on
hand, reconstitutions performed, symptoms, and weights. The operator is
the person holding the phone. They choose the model endpoint and supply
the API key.

## What it does

- Turns a ramble and optional on-device label OCR into a list of proposed
  events plus a gap list.
- Files confirmed events into an append-only JSONL ledger on the phone.
- Converts numbers the user typed (mass, diluent, intended dose) into
  concentration, draw volume, and syringe marks, showing every input and
  the formula.
- Exports the full ledger as JSONL and CSV through the system share sheet.

Every proposed row is a draft. The user reviews it before it becomes the
record.

## What it does not do

- Recommend, suggest, or default a dose, compound, protocol, cadence, or
  vendor.
- Convert IU to mass unless the user supplies a compound-specific factor.
- Read or write Apple Health, an EHR, or a pharmacy system.
- Coach, generate a protocol, or log food.
- Send data to a company server. There is no company server.

Time-critical or emergency use is out of scope. The clerk refuses
prescription questions.

## FDA non-device CDS

The design maps to FD&C Act section 520(o)(1)(E) as read in FDA's
January 2026 Clinical Decision Support Software guidance:

1. Inputs are text the user typed or dictated, and photographs of labels
   they already possess. The app does not acquire diagnostic images,
   waveforms, or IVD signals. Label OCR is text recognition, not a
   medical imaging analysis.
2. Outputs display and reorganize information the user supplied (ledger
   rows, unit conversions of typed numbers).
3. Outputs are records and conversions, not treatment directives or
   patient-specific scores. The app does not tell the user what to take.
4. The user can independently review the basis: each proposed row carries
   an excerpt; DoseMath shows the formula and every input; gaps are listed
   instead of invented.

See `docs/regulatory-checklist.md` for the per-surface mapping.

## HIPAA

The project distributes source code, not a hosted service, and never
receives health data. No business associate agreement with this project
exists or is needed. The user's model provider is an egress they chose.
See `docs/permissions-and-data.md`.
