/******************************************
  Get available zones in region
 *****************************************/
data "google_compute_zones" "available" {
  count = local.zone_count == 0 ? 1 : 0

  provider = google

  project = var.project_id
  region  = local.region
}

resource "random_shuffle" "available_zones" {
  count = local.zone_count == 0 ? 1 : 0

  input        = data.google_compute_zones.available[0].names
  result_count = 3
}

locals {
  // ID of the cluster
  cluster_id = google_container_cluster.primary.id

  // location
  location = var.regional ? var.region : var.zones[0]
  region   = var.regional ? var.region : join("-", slice(split("-", var.zones[0]), 0, 2))
  // for regional cluster - use var.zones if provided, use available otherwise, for zonal cluster use var.zones with first element extracted
  node_locations = var.regional ? coalescelist(compact(var.zones), try(sort(random_shuffle.available_zones[0].result), [])) : slice(var.zones, 1, length(var.zones))
  // Kubernetes version
  master_version_regional = var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.region.latest_master_version
  master_version_zonal    = var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.zone.latest_master_version
  master_version          = var.regional ? local.master_version_regional : local.master_version_zonal
  // Build a map of maps of node pools from a list of objects
  node_pool_names         = [for np in toset(var.node_pools) : np.name]
  node_pools              = zipmap(local.node_pool_names, tolist(toset(var.node_pools)))

  gateway_api_config = var.gateway_api_channel != null ? [{ channel : var.gateway_api_channel }] : []
  network_project_id          = var.network_project_id != "" ? var.network_project_id : var.project_id
  zone_count                  = length(var.zones)
  cluster_type                = var.regional ? "regional" : "zonal"

  cluster_network_policy = var.network_policy ? [{
    enabled  = true
    provider = var.network_policy_provider
    }] : [{
    enabled  = false
    provider = null
  }]

  cluster_output_regional_zones = google_container_cluster.primary.node_locations
  cluster_output_zones          = local.cluster_output_regional_zones
  cluster_endpoint           = (var.enable_private_nodes && length(google_container_cluster.primary.private_cluster_config) > 0) ? (var.deploy_using_private_endpoint ? google_container_cluster.primary.private_cluster_config[0].private_endpoint : google_container_cluster.primary.private_cluster_config[0].public_endpoint) : google_container_cluster.primary.endpoint

  cluster_output_node_pools_names = concat(
    [for np in google_container_node_pool.pools : np.name], [""]
  )

  cluster_output_node_pools_versions = merge(
    { for np in google_container_node_pool.pools : np.name => np.version }
  )


  cluster_location = google_container_cluster.primary.location
  cluster_region   = var.regional ? var.region : join("-", slice(split("-", local.cluster_location), 0, 2))
  cluster_zones    = sort(local.cluster_output_zones)

  // node pool ID is in the form projects/<project-id>/locations/<location>/clusters/<cluster-name>/nodePools/<nodepool-name>
  cluster_name_parts_from_nodepool           = split("/", element(values(google_container_node_pool.pools)[*].id, 0))
  cluster_name_computed                      = element(local.cluster_name_parts_from_nodepool, length(local.cluster_name_parts_from_nodepool) - 3)
  cluster_node_pools_names                   = local.cluster_output_node_pools_names
  workload_identity_enabled                  = !(var.identity_namespace == null || var.identity_namespace == "null")
  cluster_workload_identity_config = !local.workload_identity_enabled ? [] : var.identity_namespace == "enabled" ? [{
    workload_pool = "${var.project_id}.svc.id.goog" }] : [{ workload_pool = var.identity_namespace
  }]
}

/******************************************
  Get available container engine versions
 *****************************************/
data "google_container_engine_versions" "region" {
  location = local.location
  project  = var.project_id
}

data "google_container_engine_versions" "zone" {
  // Work around to prevent a lack of zone declaration from causing regional cluster creation from erroring out due to error
  //
  //     data.google_container_engine_versions.zone: Cannot determine zone: set in this resource, or set provider-level zone.
  //
  location = local.zone_count == 0 ? data.google_compute_zones.available[0].names[0] : var.zones[0]
  project  = var.project_id
}