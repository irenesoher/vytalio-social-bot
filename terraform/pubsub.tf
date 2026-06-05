resource "google_pubsub_topic" "webhook_events" {
  name                       = "meta-webhook-events"
  project                    = var.project_id
  message_retention_duration = "600s"  # 10 minutos
}
