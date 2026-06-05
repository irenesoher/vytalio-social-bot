terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "code_bucket" {
  name                        = "${var.project_id}-chatbot-code-bucket"
  location                    = var.region
  force_destroy               = var.environment != "prod"
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}
