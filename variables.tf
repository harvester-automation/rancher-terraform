variable "rancher_api_url" {
  description = "Rancher API endpoint"
  type        = string
  default     = "https://10.161.96.101.sslip.io"
}

variable "rancher_access_key" {
  description = "Rancher API access key"
  type        = string
  sensitive   = true
}

variable "rancher_secret_key" {
  description = "Rancher API secret key"
  type        = string
  sensitive   = true
}

variable "rancher_insecure" {
  description = "Allow insecure TLS (for self-signed certificates)"
  type        = bool
  default     = true
}

variable "rancher_timeout" {
  description = "Rancher API request timeout"
  type        = string
  default     = "30m"
}

variable "cluster_name" {
  description = "RKE2 cluster name"
  type        = string
  default     = "rke2-terraform"
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

variable "control_plane_vm_spec" {
  description = "VM specification for control plane nodes"
  type = object({
    cpu_count   = string
    memory_size = string
    disk_size   = number
  })
  default = {
    cpu_count   = "4"
    memory_size = "8"
    disk_size   = 100
  }
}

variable "worker_vm_spec" {
  description = "VM specification for worker nodes"
  type = object({
    cpu_count   = string
    memory_size = string
    disk_size   = number
  })
  default = {
    cpu_count   = "4"
    memory_size = "8"
    disk_size   = 100
  }
}

variable "vm_image_name" {
  description = "VM image name (namespace/image-name)"
  type        = string
  default     = "vm-ns/image-tth9v"
}

variable "vm_network_name" {
  description = "VM network name (namespace/network-name)"
  type        = string
  default     = "vm-ns/service-vm-vlan"
}

variable "vm_namespace" {
  description = "VM namespace"
  type        = string
  default     = "vm-ns"
}
