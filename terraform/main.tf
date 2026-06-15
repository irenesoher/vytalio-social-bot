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
# Habilita la API de presupuestos en tu proyecto
resource "google_project_service" "billing_budgets" {
  project = var.project_id
  service = "billingbudgets.googleapis.com"

  disable_on_dependency = false
  disable_on_destroy    = false
}

# Obtiene la cuenta de facturación ligada a tu proyecto
data "google_billing_account" "account" {
  billing_account = null # Busca automáticamente la cuenta activa del proyecto
  open            = true
}

# Crea la alerta de presupuesto de 2 USD
resource "google_billing_budget" "budget" {
  depends_on      = [google_project_service_billing_budgets]
  billing_account = data.google_billing_account.account.id
  display_name    = "Presupuesto de Seguridad Bot Vytalio"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "2" # Tu límite estricto de 2 dólares
    }
  }

  # Te avisará a tu correo cuando llegues al 50%, 80% y 100% del gasto
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  # Alerta si el pronóstico (forecast) dice que vas a pasarte del 100%
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }
}
