# variables.tf

variable "project_id" {
  description = "The GCP project to use for integration tests"
  type        = string
}

variable "region" {
  description = "The GCP region to create and test resources in"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP zone to create resources in"
  type        = string
  default     = null
}
