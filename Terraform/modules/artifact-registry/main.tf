# Artifact Registry Repository
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.prefix}-docker-repo"
  description   = "Private Docker repository"
  format        = "DOCKER"
}
