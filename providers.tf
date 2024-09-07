terraform {
    required_version = ">=1.3"
    
    required_providers {
      google = {
        source = "hashicorp/google"
        version = ">= 5.9.0, < 6"
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
      name = "value"
    }
}

provider "google" {
    project = var.project_id
}