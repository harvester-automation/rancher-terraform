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
