output "cluster_id" {
    description = "Cluster Id"
    value = module.gke.cluster_id
}

output "name" {
    description = "Cluster Name"
    value = module.gke.name
}

output "type" {
    description = "Cluster type (regional / zonal)"
    value = module.gke.type
}

output "location" {
    description = "Cluster location (region if regional cluster, zone if zonal cluster)"
    value = module.gke.location
}

output "region" {
    description = "Cluster Region"
    value = module.gke.region
}

output "zones" {
    description = "List of zones in which the cluster resides"
    value = module.gke.zones
}


output "master_authorized_networks_config" {
    description = "Networks from which access to master is permitted"
    value = module.gke.master_authorized_networks_config
}


output "node_pools_names" {
    description = "List of node pools names"
    value = module.gke.node_pools_names
}

output "instance_group_urls" {
    description = "List of GKE generated instance groups"
    value = module.gke.instance_group_urls
}

output "master_ipv4_cidr_block" {
    description = "The IP range in CIDR notation used for the hosted master network"
    value = module.gke.master_ipv4_cidr_block
}