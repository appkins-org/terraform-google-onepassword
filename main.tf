resource "random_id" "connect" {
  byte_length = 2
}

resource "google_service_account" "connect" {
  project      = var.project
  account_id   = var.service_account_id
  display_name = "Onepassword Service Account"
}

resource "google_secret_manager_secret" "credentials" {
  secret_id = local.secret_name
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "credentials" {
  secret      = google_secret_manager_secret.credentials.name
  secret_data = var.credential_data
}

resource "google_secret_manager_secret_iam_member" "secret-access" {
  secret_id = google_secret_manager_secret.credentials.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.connect.email}"
}

resource "google_cloud_run_v2_service" "default" {
  name     = var.name
  project  = var.project
  location = var.location

  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "BETA"

  template {
    service_account = google_service_account.connect.email

    scaling {
      max_instance_count = var.max_instance_count
    }

    max_instance_request_concurrency = var.max_concurrency

    containers {
      name = "api"

      image = "1password/connect-api:latest"

      env {
        name  = "OP_HTTP_PORT"
        value = 8080
      }

      ports {
        name           = "http1"
        container_port = 8080
      }

      startup_probe {
        period_seconds        = 30
        failure_threshold     = 3
        initial_delay_seconds = 15

        tcp_socket {
          port = 8080
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }

      volume_mounts {
        name       = "data"
        mount_path = "/home/opuser/.op/data"
      }

      volume_mounts {
        name       = "credentials"
        mount_path = "/home/opuser/.op"
      }
    }

    containers {
      name = "sync"

      image = "1password/connect-sync:latest"

      env {
        name  = "OP_HTTP_PORT"
        value = "8081"
      }

      ports {
        name           = "http1"
        container_port = 8081
      }

      liveness_probe {
        initial_delay_seconds = 15
        failure_threshold     = 3
        period_seconds        = 30

        http_get {
          path = "/heartbeat"
          port = 8081
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }

      volume_mounts {
        name       = "data"
        mount_path = "/home/opuser/.op/data"
      }
    }

    volumes {
      name = "data"

      empty_dir {
        medium     = "Memory"
        size_limit = "128Mi"
      }
    }

    volumes {
      name = "credentials"
      secret {
        secret       = google_secret_manager_secret.credentials.secret_id
        default_mode = 292 # 0444
        items {
          version = google_secret_manager_secret_version.credentials.version
          path    = "1password-credentials.json"
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_v2_service.default.location
  project  = google_cloud_run_v2_service.default.project
  service  = google_cloud_run_v2_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_domain_mapping" "default" {
  count = var.custom_domain != "" ? 1 : 0

  location = google_cloud_run_v2_service.default.location
  name     = var.custom_domain

  metadata {
    namespace = google_cloud_run_v2_service.default.project
  }

  spec {
    route_name = google_cloud_run_v2_service.default.name
  }
}
