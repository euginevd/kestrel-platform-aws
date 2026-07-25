# Logging & Monitoring step 4 — what the coverage query enumerates against.
#
# The success criterion is "a coverage query across the whole
# organisation returns zero gaps", and that query needs something to ask
# WHICH VPCS EXIST before it can ask which of them are logging. Without
# an org-wide index, coverage is checked against the list someone
# remembered to maintain — which is exactly the failure the criterion
# exists to catch.
#
# Resource Explorer aggregates by OU from the delegated admin, so a
# vended account appears in the index with no per-account step.

resource "aws_resourceexplorer2_index" "aggregator" {
  type = "AGGREGATOR" # one per org, in the delegated admin account

  tags = local.standard_tags
}

resource "aws_resourceexplorer2_view" "all" {
  name         = "kestrel-all-resources"
  default_view = true

  included_property {
    name = "tags"
  }

  tags = local.standard_tags

  depends_on = [aws_resourceexplorer2_index.aggregator]
}
