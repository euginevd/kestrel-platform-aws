# ADR-0003 — Terraform-native engine, self-managed state

Status: Accepted · Date: 2026-07-20 · Part: Bootstrap (decisions 1–3)

## Context

Three ways to stand up a regulated multi-account foundation converge on
the same shape (SRA tree, delegated admin, central logging, federated
identity): Control Tower + LZA, Control Tower + AFT, or Terraform-native
on Organizations. State contains secrets, so where it sits is a security
decision of its own.

## Decision

**Terraform-native on Organizations**, on GitHub Enterprise Cloud with
Australian data residency. Defensibility — the SSP is answered from code
we wrote; portability — the same pattern carries to Azure and GCP; and
no ClickOps in the foundation. Terraform over OpenTofu because the
HashiCorp support agreement covers Terraform; OpenTofu is the documented
exit, its state-encryption advantage answered by SSE-KMS.

**Self-managed S3 state backend** in shared-services: versioned,
SSE-KMS, Object-Locked (GOVERNANCE 30d — a rollback window, not
COMPLIANCE, because state can hold a provider-generated secret), native
S3 locking. HCP Terraform has no Australian region as of July 2026 —
fails sovereignty on arrival; TFE self-hosted is the cost-driven
fallback. **State per account-component leaf** — one root config, one
state key, never one estate-wide state.

**GitHub-hosted runners with OIDC**, split plan/apply roles. The
accepted cost, stated plainly: runner compute sits outside the assessed
boundary; state at rest never leaves it. Two flip triggers, either
alone: a plan touching a PROTECTED workload account, or a leaf whose
state holds a genuine secret — then self-hosted runners, apply job
first.

## Consequences

We own state hygiene, drift and RBAC, and rebuild what a platform would
have sold: Checkov for Sentinel, vendored modules for a registry, the PR
and Actions log as the audit trail. Flip conditions recorded per choice.
