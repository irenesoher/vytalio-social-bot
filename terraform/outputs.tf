output "webhook_url" {
  value       = google_cloudfunctions2_function.webhook_ingestor.service_config[0].uri
  description = "Copia esta URL y pégala en el panel de Meta Developers como Callback URL"
  sensitive   = false
}

output "processor_name" {
  value       = google_cloudfunctions2_function.webhook_processor.name
  description = "Nombre del procesador — úsalo para ver logs: gcloud functions logs read <nombre>"
  sensitive   = false
}
