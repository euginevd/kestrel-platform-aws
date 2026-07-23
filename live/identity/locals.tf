locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "security-team@kestrel.com.au"
    CostCentre         = "CC-SECURITY"
    Application        = "landing-zone"
  }
}

data "aws_ssoadmin_instances" "this" {} # the instance Organisation created

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}
