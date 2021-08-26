# Configure the Google Cloud tfstate file location
terraform {
  backend "gcs" {
    bucket = "infra-admin-307815"
    prefix = "terraform-admin-gke"
  }
}
