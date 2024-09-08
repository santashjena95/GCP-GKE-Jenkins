resource "google_artifact_registry_repository" "googleartifactregistry" {
    for_each      = var.repository_name
    location      = var.region
    repository_id = "${substr(var.environment, 0, 1)}${var.channel_name}${var.portfolio_name}-${each.value}"
    description   = "Artifact Registry"
    format        = "Docker"
}