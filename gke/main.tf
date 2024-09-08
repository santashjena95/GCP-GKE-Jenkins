data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    module.gke.cluster_ca_certificate,
  )
}

module "gke" {
  source  = "../module"

  project_id                = var.project_id
  cluster_name              = var.cluster_name
  regional                  = var.regional
  region                    = var.region
  network                   = var.network
  subnetwork                = var.subnetwork
  ip_range_pods             = var.ip_range_pods
  ip_range_services         = var.ip_range_services
  service_account           = var.service_account
  enable_private_endpoint   = var.enable_private_endpoint
  enable_private_nodes      = var.enable_private_nodes
  master_ipv4_cidr_block    = var.master_ipv4_cidr_block
  default_max_pods_per_node = var.default_max_pods_per_node
  remove_default_node_pool  = var.remove_default_node_pool
  deletion_protection       = var.deletion_protection

  node_pools = [
    {
      name              = var.nodepool_name
      min_count         = var.nodepool_mincount
      max_count         = var.nodepool_maxcount
      disk_size_gb      = var.nodepool_disk_size
      disk_type         = var.nodepool_disk_type
      service_account   = var.service_account
      max_pods_per_node = var.default_max_pods_per_node
    },
  ]

  repository_name = var.repository_name
  channel_name = var.channel_name
  environment  = var.environment
  portfolio_name = var.portfolio_name
}