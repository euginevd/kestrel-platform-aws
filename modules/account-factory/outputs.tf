output "account_id" {
  value = aws_organizations_account.this.id
}

output "account_name" {
  value = aws_organizations_account.this.name
}
