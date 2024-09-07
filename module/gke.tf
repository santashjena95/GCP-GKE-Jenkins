/******************************************
  Create Container Cluster
 *****************************************/
resource "google_container_cluster" "primary" {
  provider = google

  name            = var.cluster_name
  description     = var.description
  project         = var.project_id
  location            = local.location
  node_locations      = local.node_locations
  cluster_ipv4_cidr   = var.cluster_ipv4_cidr
  remove_default_node_pool = var.remove_default_node_pool
  network             = "projects/${local.network_project_id}/global/networks/${var.network}"
  subnetwork = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"
  deletion_protection = var.deletion_protection
  
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [var.enable_binary_authorization] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }
  dynamic "network_policy" {
    for_each = local.cluster_network_policy

    content {
      enabled  = network_policy.value.enabled
      provider = network_policy.value.provider
    }
  }
  dynamic "gateway_api_config" {
    for_each = local.gateway_api_config

    content {
      channel = gateway_api_config.value.channel
    }
  }
  cluster_autoscaling {
    enabled = var.cluster_autoscaling.enabled
    dynamic "auto_provisioning_defaults" {
      for_each = var.cluster_autoscaling.enabled ? [1] : []

      content {
        service_account = var.service_account
        oauth_scopes    = local.node_pools_oauth_scopes["all"]

        management {
          auto_repair  = lookup(var.cluster_autoscaling, "auto_repair", true)
          auto_upgrade = lookup(var.cluster_autoscaling, "auto_upgrade", true)
        }

        disk_size = lookup(var.cluster_autoscaling, "disk_size", 30)
        disk_type = lookup(var.cluster_autoscaling, "disk_type", "pd-standard")

       }
      }
      autoscaling_profile = var.cluster_autoscaling.autoscaling_profile != null ? var.cluster_autoscaling.autoscaling_profile : "BALANCED"
  }
  dynamic "master_authorized_networks_config" {
    for_each = var.enable_private_endpoint || length(var.master_authorized_networks) > 0 ? [true] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }
  node_pool {
    name               = "systempool"
    initial_node_count = var.initial_node_count

    node_config {
      image_type                  = lookup(var.node_pools[0], "image_type", "COS_CONTAINERD")
      machine_type                = lookup(var.node_pools[0], "machine_type", "e2-medium")
      min_cpu_platform            = lookup(var.node_pools[0], "min_cpu_platform", "")
      service_account = lookup(var.node_pools[0], "service_account", var.service_account)
    }
  }

  dynamic "workload_identity_config" {
    for_each = local.cluster_workload_identity_config

    content {
      workload_pool = workload_identity_config.value.workload_pool
    }
  }

  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [{
      enable_private_nodes        = var.enable_private_nodes,
      enable_private_endpoint     = var.enable_private_endpoint
      master_ipv4_cidr_block      = var.master_ipv4_cidr_block
    }] : []

    content {
      enable_private_endpoint     = private_cluster_config.value.enable_private_endpoint
      enable_private_nodes        = private_cluster_config.value.enable_private_nodes
      master_ipv4_cidr_block      = private_cluster_config.value.master_ipv4_cidr_block
      dynamic "master_global_access_config" {
        for_each = var.master_global_access_enabled ? [var.master_global_access_enabled] : []
        content {
          enabled = master_global_access_config.value
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [node_pool, initial_node_count, resource_labels["asmv"]]
  }
}
/******************************************
  Create Container Cluster node pools
 *****************************************/
resource "google_container_node_pool" "pools" {
  provider = google
  for_each = local.node_pools
  name     = each.key
  project  = var.project_id
  location = local.location
  // use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations = lookup(each.value, "node_locations", "") != "" ? split(",", each.value["node_locations"]) : null

  cluster = google_container_cluster.primary.name

  initial_node_count = lookup(each.value, "autoscaling", true) ? lookup(
    each.value,
    "initial_node_count",
    lookup(each.value, "min_count", 1)
  ) : null

  max_pods_per_node = lookup(each.value, "max_pods_per_node", null)

  node_count = lookup(each.value, "autoscaling", true) ? null : lookup(each.value, "node_count", 1)

  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count       = contains(keys(autoscaling.value), "total_min_count") ? null : lookup(autoscaling.value, "min_count", 1)
      max_node_count       = contains(keys(autoscaling.value), "total_max_count") ? null : lookup(autoscaling.value, "max_count", 100)
      location_policy      = lookup(autoscaling.value, "location_policy", null)
      total_min_node_count = lookup(autoscaling.value, "total_min_count", null)
      total_max_node_count = lookup(autoscaling.value, "total_max_count", null)
    }
  }

  dynamic "network_config" {
    for_each = length(lookup(each.value, "pod_range", "")) > 0 ? [each.value] : []
    content {
      pod_range            = lookup(network_config.value, "pod_range", null)
      enable_private_nodes = lookup(network_config.value, "enable_private_nodes", null)
    }
  }

  node_config {
    image_type                  = lookup(each.value, "image_type", "COS_CONTAINERD")
    machine_type                = lookup(each.value, "machine_type", "e2-medium")
    min_cpu_platform            = lookup(each.value, "min_cpu_platform", "")
    disk_size_gb    = lookup(each.value, "disk_size_gb", 30)
    disk_type       = lookup(each.value, "disk_type", "pd-standard")

    service_account = lookup(
      each.value,
      "service_account",
      var.service_account,
    )
    preemptible = lookup(each.value, "preemptible", false)
    spot        = lookup(each.value, "spot", false)

    oauth_scopes = concat(
      local.node_pools_oauth_scopes["all"],
      local.node_pools_oauth_scopes[each.value["name"]],
    )
  }
  lifecycle {
    ignore_changes = [initial_node_count]
  }
}