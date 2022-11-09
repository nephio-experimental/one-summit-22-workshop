# main.tf

terraform {
  required_version = ">= 1.3.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.42.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.42.0"
    }
    local = "~> 2.2.3"
    null  = "~> 3.2.0"
  }

  # backend "gcs" {
  #   # to fill in for a remote state (for instance on a gcs bucket)
  #   bucket                      = "xxxxx"
  #   prefix                      = "yyyyy"
  #   impersonate_service_account = "zzzzz"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

