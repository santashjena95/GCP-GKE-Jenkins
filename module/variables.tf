variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in (required)"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "description" {
  type        = string
  description = "The description of the cluster"
  default     = ""
}

variable "regional" {
  type        = bool
  description = "Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!)"
  default     = true
}

variable "region" {
  type        = string
  description = "The region to host the cluster in (optional if zonal cluster / required if regional)"
  default     = "us-east4"
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the cluster in (optional if regional cluster / required if zonal)"
  default     = []
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in (required)"
}

variable "network_project_id" {
  type        = string
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  default     = ""
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to host the cluster in (required)"
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "ip_range_pods" {
  type        = string
  description = "The _name_ of the secondary subnet ip range to use for pods"
}

variable "additional_ip_range_pods" {
  type        = list(string)
  description = "List of _names_ of the additional secondary subnet ip ranges to use for pods"
  default     = []
}

variable "ip_range_services" {
  type        = string
  description = "The _name_ of the secondary subnet range to use for services"
}

variable "node_pools" {
  type        = list(map(any))
  description = "List of maps containing node pools"

  default = [
    {
      name = "workerpool"
    },
  ]
}


variable "cluster_autoscaling" {
  type = object({
    enabled                     = bool
    autoscaling_profile         = string
    min_cpu_cores               = number
    max_cpu_cores               = number
    min_memory_gb               = number
    max_memory_gb               = number
    gpu_resources               = list(object({ resource_type = string, minimum = number, maximum = number }))
    auto_repair                 = bool
    auto_upgrade                = bool
    disk_size                   = optional(number)
    disk_type                   = optional(string)
  })
  default = {
    enabled                     = false
    autoscaling_profile         = "BALANCED"
    max_cpu_cores               = 0
    min_cpu_cores               = 0
    max_memory_gb               = 0
    min_memory_gb               = 0
    gpu_resources               = []
    auto_repair                 = true
    auto_upgrade                = true
    disk_size                   = 30
    disk_type                   = "pd-standard"
  }
  description = "Cluster autoscaling configuration. See [more details](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters#clusterautoscaling)"
}


variable "node_pools_oauth_scopes" {
  type        = map(list(string))
  description = "Map of lists containing node oauth scopes by node-pool name"

  # Default is being set in variables_defaults.tf
  default = {
    all               = ["https://www.googleapis.com/auth/cloud-platform"]
    workerpool = []
  }
}

variable "service_account" {
  type        = string
  description = "The service account to run nodes as if not overridden in `node_pools`. The create_service_account variable default value (true) will cause a cluster-specific service account to be created. This service account should already exists and it will be used by the node pools. If you wish to only override the service account name, you can use service_account_name variable."
  default     = ""
}
variable "gateway_api_channel" {
  type        = string
  description = "The gateway api channel of this cluster. Accepted values are `CHANNEL_STANDARD` and `CHANNEL_DISABLED`."
  default     = "CHANNEL_STANDARD"
}

variable "cluster_ipv4_cidr" {
  type        = string
  default     = null
  description = "The IP address range of the kubernetes pods in this cluster. Default is an automatically assigned CIDR."
}

variable "deploy_using_private_endpoint" {
  type        = bool
  description = "A toggle for Terraform and kubectl to connect to the master's internal IP address during deployment."
  default     = true
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Whether the master's internal IP address is used as the cluster endpoint"
  default     = true
}

variable "enable_private_nodes" {
  type        = bool
  description = "Whether nodes have internal IP addresses only"
  default     = true
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network. Optional for Autopilot clusters."
  default     = "172.16.0.0/28"
}

variable "master_global_access_enabled" {
  type        = bool
  description = "Whether the cluster master is accessible globally (from any region) or only within the same region as the private endpoint."
  default     = false
}


variable "network_policy" {
  type        = bool
  description = "Enable network policy addon"
  default     = true
}


variable "network_policy_provider" {
  type        = string
  description = "The network policy provider."
  default     = "CALICO"
}


variable "enable_binary_authorization" {
  type        = bool
  description = "Enable BinAuthZ Admission controller"
  default     = true
}


variable "identity_namespace" {
  description = "The workload pool to attach all Kubernetes service accounts to. (Default value of `enabled` automatically sets project-based pool `[project_id].svc.id.goog`)"
  type        = string
  default     = "enabled"
}

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
  default     = 1
}

variable "remove_default_node_pool" {
  type        = bool
  description = "Remove default node pool while setting up the cluster"
  default     = true
}


variable "default_max_pods_per_node" {
  type        = number
  description = "The maximum number of pods to schedule per node"
  default     = 20
}

variable "deletion_protection" {
  type        = bool
  description = "Whether or not to allow Terraform to destroy the cluster."
  default     = false
}

variable "non_masquerade_cidrs" {
  type        = list(string)
  description = "List of strings in CIDR notation that specify the IP address ranges that do not use IP masquerading."
  default     = ["10.0.0.0/24", "172.16.0.0/28", "192.168.0.0/16"]
}

variable "ip_masq_resync_interval" {
  type        = string
  description = "The interval at which the agent attempts to sync its ConfigMap file from the disk."
  default     = "60s"
}

variable "ip_masq_link_local" {
  type        = bool
  description = "Whether to masquerade traffic to the link-local prefix (169.254.0.0/16)."
  default     = false
}

variable "configure_ip_masq" {
  type        = bool
  description = "Enables the installation of ip masquerading, which is usually no longer required when using aliasied IP addresses. IP masquerading uses a kubectl call, so when you have a private cluster, you will need access to the API server."
  default     = true
}

variable "repository_name" {
  type        = set(string)
  description = "Google Artifact Registry Name"
}

variable "channel_name" {
  type        = string
  description = "Application Channel Name"
}

variable "environment" {
  type        = string
  description = "Environment for the GKE Cluster"
}

variable "portfolio_name" {
  type        = string
  description = "Application Portfolio Name"
}