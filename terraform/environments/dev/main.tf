resource "random_id" "id" {
  byte_length = 4
}
# ===== Create S3 bucket for Terraform state =====
resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-terraform-state-${random_id.id.hex}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
# ===== End of S3 bucket for Terraform state =====