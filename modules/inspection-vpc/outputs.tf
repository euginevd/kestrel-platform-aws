output "vpc_id" {
  value = aws_vpc.this.id
}

output "attachment_id" {
  value = aws_networkmanager_vpc_attachment.this.id
}
