terraform {
    required_version = ">=1.3"
    
    required_providers {
      google = {
        source = "hashicorp/google"
        version = ">= 5.40.0, < 6"
      }
      kubernetes = {
        source = "hashicorp/kubernetes"
        version = "~> 2.10"
      }
      random = {
        source = "hashicorp/random"
        version = ">= 2.1"
      }
    }
    backend "gcs" {
      bucket = "devops-sre-terraform-state-file"
      prefix = "env/dev"
    }
}

provider "google" {
    project = var.project_id
}