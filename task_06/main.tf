# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 1.0"
}

# Create a server
resource "hcloud_server" "helloServer" {
  name        = "hello"
  image       = "debian-12"
  server_type = "cx22"
}
