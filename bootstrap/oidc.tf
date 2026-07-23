# Steps 9–10 — pipeline identity: one OIDC provider and one pair of split
# run roles per account a pipeline will ever touch. The last laptop apply
# in the estate's history: after this, the pipeline creates everything.
#
# Module source is a relative path here because bootstrap runs before the
# pipeline (and its tag-pinning check) exists; live/ leaves consume
# modules pinned by git tag.

module "oidc_management" {
  source = "../modules/github-oidc"

  tags = local.standard_tags
}

module "oidc_shared_services" {
  source = "../modules/github-oidc"

  providers = {
    aws = aws.shared_services
  }

  tags = local.standard_tags
}

# Accounts vended later get their provider and roles from the factory's
# birth baseline (live/management/accounts/) — KestrelDeploy first, because
# every later step and every future apply arrives through it.
