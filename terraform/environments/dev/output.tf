# === Output variables for the S3 bucket ===
output "s3_bucket_id" {
  value       = aws_s3_bucket.terraform_state.id
  description = "ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket"
}
# === End of output variables for the S3 bucket ===