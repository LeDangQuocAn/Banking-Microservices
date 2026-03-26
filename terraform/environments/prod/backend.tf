terraform {
  cloud {
    organization = "devsecops-tfstate-microservices"
    workspaces {
      name = "banking-ms-prod"
    }
  }
}
