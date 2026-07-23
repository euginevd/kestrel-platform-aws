# This leaf routes to the management account (accounts.json: management).
# In the pipeline the job has already assumed KestrelPlan or KestrelDeploy
# there via OIDC, so no assume_role block is needed here.

provider "aws" {
  region = "ap-southeast-2"
}
