# Service Account dedicado para el processor
resource "google_service_account" "processor_sa" {
  account_id   = "meta-webhook-processor-sa"
  display_name = "SA para el procesador de webhooks Meta"
  project      = var.project_id
}

# Puede leer secrets
resource "google_project_iam_member" "processor_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.processor_sa.email}"
}

# Puede usar Vertex AI / Gemini
resource "google_project_iam_member" "processor_vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.processor_sa.email}"
}

# Puede escribir logs
resource "google_project_iam_member" "processor_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.processor_sa.email}"
}

# Service Account para el ingestor
resource "google_service_account" "ingestor_sa" {
  account_id   = "meta-webhook-ingestor-sa"
  display_name = "SA para el ingestor de webhooks Meta"
  project      = var.project_id
}

# Puede publicar en Pub/Sub
resource "google_project_iam_member" "ingestor_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.ingestor_sa.email}"
}

# Puede leer secrets (VERIFY_TOKEN y META_APP_SECRET)
resource "google_project_iam_member" "ingestor_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.ingestor_sa.email}"
}
