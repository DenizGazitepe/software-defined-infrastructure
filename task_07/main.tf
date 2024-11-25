# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 1.0"
}

# Setup the firewall
resource "hcloud_firewall" "sshFw" {
  name = "ssh-firewall"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
# Add the ssh keys
resource "hcloud_ssh_key" "loginDeniz" {
  name       = "deniz@LegionSlim7-Deniz"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICF0ll5wZPXwKvIqo9Dvp0bLJVu54pvHhji6i73pgiOE"
}

resource "hcloud_ssh_key" "loginGoik" {
  name       = "goik@hdm-stuttgart.de"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKY24AeEibQGSMPtstaN4REByLCM3kzjM//apEZ9WyUB goik@hdm-stuttgart.de"
}

resource "hcloud_ssh_key" "loginNico" {
  name       = "nico@Nasbert"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9FnrukU1in+njcoOtPe7Z1yYLqlGD6tBebrq/GFVRQ nico@Nasbert"
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
  loginUser = "devops"
  })
  filename = "gen/userData.yml"
}

# Create a server
resource "hcloud_server" "helloServer" {
  name         = "hello"
  image        = "debian-12"
  server_type  = "cx22"
  datacenter   = "nbg1-dc3"
  firewall_ids = [hcloud_firewall.sshFw.id]
  ssh_keys     = [hcloud_ssh_key.loginDeniz.id, hcloud_ssh_key.loginNico.id, hcloud_ssh_key.loginGoik.id]
  // New stuff here, Fig. 1001, Yaml file contains commands that should be run when the server is created
  user_data = file("userData.yml")
}

