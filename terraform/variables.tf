variable "project_id" {
  type        = string
  description = "El ID de tu proyecto en Google Cloud"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "La región de GCP donde se desplegarán los servicios"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Entorno: dev | staging | prod — controla si el bucket se puede destruir"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser dev, staging o prod."
  }
}
