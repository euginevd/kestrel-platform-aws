# GitHub OIDC federation for one AWS account — Bootstrap steps 9–10.
#
# A provider grants nothing on its own; the two roles below reference it,
# and their trust policies ARE the security boundary. Plan and apply are
# two separate IAM roles with different trust conditions — plan is
# read-only and assumable from a PR, only apply can write and only from
# the pinned environment.

resource "aws_iam_openid_connect_provider" "github" {
  # No thumbprint_list on purpose — AWS validates GitHub's certificate
  # against its own trust store for this issuer.
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"] # the audience GitHub requests

  tags = var.tags
}

# --- Apply: write-capable, environment-pinned --------------------------------

data "aws_iam_policy_document" "apply_trust" {
  statement {
    sid     = "GitHubActionsApply"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals" # NOT StringLike — a wildcard hands over the estate
      variable = "token.actions.githubusercontent.com:sub"
      # Immutable owner/repo IDs, enforced since 15 Jul 2026; pin the
      # ENVIRONMENT, not the branch.
      values = [
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}:environment:${var.apply_environment}",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      # Belt-and-braces: even a sub-claim bug can't cross an owner boundary.
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_owner_id"
      values   = [var.github_owner_id]
    }
  }
}

resource "aws_iam_role" "apply" {
  # KestrelDeploy is THE deployment role name — Guardrails'
  # protect-platform SCP carves it out of every deny and reserves the
  # name so nobody else can create it.
  name               = "KestrelDeploy"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "apply" {
  role = aws_iam_role.apply.name
  # The platform repo manages the org itself, so the apply role is broad
  # by necessity — its containment is the trust policy above, the
  # production-environment approval gate, and CloudTrail attribution.
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Plan: read-only, assumable from a PR ------------------------------------

data "aws_iam_policy_document" "plan_trust" {
  statement {
    sid     = "GitHubActionsPlan"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      # The plan role differs in exactly two ways: sub ends :pull_request,
      # policy is ReadOnlyAccess.
      values = [
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}:pull_request",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_owner_id"
      values   = [var.github_owner_id]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "KestrelPlan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "plan" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
