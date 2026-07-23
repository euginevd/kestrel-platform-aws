# Security

This is a **reference implementation for a fictional scenario**. Nothing in this
repository is deployed anywhere, no identifier here refers to real infrastructure, and
no credential or secret of any kind should ever exist in this history — the org ID,
account IDs and email domains are all placeholders.

## Reporting

If you find something that looks like a real secret, a real account ID, or a security
flaw in the patterns this repo demonstrates, open a
[private security advisory](https://github.com/euginevd/kestrel-platform-aws/security/advisories/new)
on this repository. Please don't open a public issue for anything that could be a
leaked credential.

Because there is no running estate behind this code, there is no operational impact to
coordinate — reports are about the correctness of the reference material itself, and
they're welcome.

## What this repo enforces on itself

The repo demonstrates its own gates: a protected `main`, CODEOWNERS-required review,
and a credential-free checks workflow (`terraform fmt`, `validate`, Checkov against
`policy/`, gitleaks) that runs with no cloud access and no secrets — there is nothing
here worth stealing, and the pipeline is built so that stays true.
