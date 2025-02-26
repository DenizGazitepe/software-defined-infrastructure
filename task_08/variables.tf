variable "hcloud_token" {
  nullable = false
  sensitive = true
}

variable "tls_private_key" {
  type      = string
  sensitive = true
}