locals {
   node_pools_oauth_scopes = merge(
     { all = ["https://www.googleapis.com/auth/cloud-platform"] },
     { workerpool = [] },
     zipmap(
       [for node_pool in var.node_pools : node_pool["name"]],
       [for node_pool in var.node_pools : []]
     ),
     var.node_pools_oauth_scopes
   )
}