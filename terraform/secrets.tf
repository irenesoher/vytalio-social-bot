resource "google_secret_manager_secret" "meta_verify_token" {
  secret_id = "meta-verify-token"
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "meta_page_token" {
  secret_id = "meta-page-access-token"
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "meta_app_secret" {
  secret_id = "meta-app-secret"
  project   = var.project_id
  replication {
    auto {}
  }
}
