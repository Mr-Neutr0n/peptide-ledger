# Evaluation fixtures

25 dictated rambles and 10 synthetic vial-label texts. None of these are real patient records.

## Mock run (CI)

`swift test --filter EvalTests` loads each ramble, answers it with a `MockProvider` that returns the fixture's `proposal` JSON, and checks kinds plus gap presence. Label fixtures go through `LabelFieldParser` only. No network.

## Live key (optional, never in CI)

```sh
export PEPTIDE_LEDGER_PROVIDER=anthropic   # or openai
export PEPTIDE_LEDGER_API_KEY=...          # not committed
export PEPTIDE_LEDGER_MODEL=claude-sonnet-4-5
export PEPTIDE_LEDGER_BASE_URL=https://api.anthropic.com
swift test --filter EvalTests.live
```

Live comparison is skipped unless `PEPTIDE_LEDGER_API_KEY` is set. The live test still refuses to print the key.
