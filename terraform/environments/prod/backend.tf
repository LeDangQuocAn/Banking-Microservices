terraform {
  backend "s3" {
    bucket       = "devops-terraform-state-c099bc7a"
    key          = "prod/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}
