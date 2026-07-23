output "apply_role_arn" {
  value = aws_iam_role.apply.arn
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
