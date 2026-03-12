terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      # Fixes rkeK8sSystemImage schema error in Rancher 2.12.1+
      # GitHub Issue #51753: https://github.com/rancher/rancher/issues/51753
      version = "~> 8.0"
    }
  }
}

provider "rancher2" {
  api_url    = var.rancher_api_url
  access_key = var.rancher_access_key
  secret_key = var.rancher_secret_key
  insecure   = var.rancher_insecure
  timeout    = var.rancher_timeout
}
