# Self-assessment

Self-assessment on IRAP methodology — **not an IRAP assessment**; that
requires a registered assessor. The value is arriving at the real one
pre-failed and pre-fixed: the estate re-runs every part's battery,
raises unsoftened findings (severity, control reference, observed versus
expected), and dispositions each as a PR — fixed and re-tested, excepted
with expiry on the register, or a signed risk acceptance in `docs/adr/`.

Two rules govern the run. Nothing is produced for the assessment — a
claim with no existing evidence object is a finding, not a request to go
make one. And the matrix never contains evidence — references only, so
`log-archive` stays the single source.

- `matrix.yaml` — the pinned release, posture and control rows
- `findings/` — one file per finding, in the assessor's format
- The full pack exports to `s3://kestrel-log-archive/irap/phase-09/`
