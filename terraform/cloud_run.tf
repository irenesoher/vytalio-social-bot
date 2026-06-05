# =====================================================================
# COMPONENTE 1: INGESTOR
# =====================================================================
data "archive_file" "ingest_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/ingestion"
  output_path = "${path.module}/files/ingestion.zip"
}

resource "google_storage_bucket_object" "ingest_object" {
  name   = "ingestion-${data.archive_file.ingest_zip.output_md5}.zip"
  bucket = google_storage_bucket.code_bucket.name
  source = data.archive_file.ingest_zip.output_path
}

resource "google_cloudfunctions2_function" "webhook_ingestor" {
  name        = "meta-webhook-ingestor"
  location    = var.region
  project     = var.project_id
  description = "Endpoint público que recibe webhooks de Facebook e Instagram"

  build_config {
    runtime     = "python312"
    entry_point = "webhook_receiver"
    source {
      storage_source {
        bucket = google_storage_bucket.code_bucket.name
        object = google_storage_bucket_object.ingest_object.name
      }
    }
  }

  service_config {
    max_instance_count = 20
    available_memory   = "256M"
    timeout_seconds    = 15

    environment_variables = {
      PUBSUB_TOPIC_ID = google_pubsub_topic.webhook_events.id
    }

    secret_environment_variables {
      key     = "VERIFY_TOKEN"
      project = var.project_id
      secret  = google_secret_manager_secret.meta_verify_token.secret_id
      version = "latest"
    }

    secret_environment_variables {
      key     = "META_APP_SECRET"
      project = var.project_id
      secret  = google_secret_manager_secret.meta_app_secret.secret_id
      version = "latest"
    }
  }
}

resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloudfunctions2_function.webhook_ingestor.location
  project  = google_cloudfunctions2_function.webhook_ingestor.project
  service  = google_cloudfunctions2_function.webhook_ingestor.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# =====================================================================
# COMPONENTE 2: PROCESADOR
# =====================================================================
data "archive_file" "processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/processor"
  output_path = "${path.module}/files/processor.zip"
}

resource "google_storage_bucket_object" "processor_object" {
  name   = "processor-${data.archive_file.processor_zip.output_md5}.zip"
  bucket = google_storage_bucket.code_bucket.name
  source = data.archive_file.processor_zip.output_path
}

resource "google_cloudfunctions2_function" "webhook_processor" {
  name        = "meta-webhook-processor"
  location    = var.region
  project     = var.project_id
  description = "Procesa los mensajes con Vertex AI (Gemini) y responde a Meta"

  build_config {
    runtime     = "python312"
    entry_point = "pubsub_processor"
    source {
      storage_source {
        bucket = google_storage_bucket.code_bucket.name
        object = google_storage_bucket_object.processor_object.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "512M"
    timeout_seconds    = 60

    secret_environment_variables {
      key     = "PAGE_ACCESS_TOKEN"
      project = var.project_id
      secret  = google_secret_manager_secret.meta_page_token.secret_id
      version = "latest"
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.webhook_events.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
