# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 1.0"
}

# Generate random root password
resource "random_password" "root_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*-_=+?"
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

# Generate the TLS private key
resource "tls_private_key" "host" {
  algorithm = "ED25519"
}

# Add the ssh keys
resource "hcloud_ssh_key" "loginDeniz" {
  name       = "dg102@hdm-stuttgart.de"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHo157bpi8OVPIv9WPPfKlcWmCu+68E3Ii5nfjtarAU dg102@hdm-stuttgart.de"
}
resource "hcloud_ssh_key" "loginGoik" {
  name       = "goik@hdm-stuttgart.de"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKY24AeEibQGSMPtstaN4REByLCM3kzjM//apEZ9WyUB goik@hdm-stuttgart.de"
}
resource "hcloud_ssh_key" "loginNico" {
  name       = "nico@Nasbert"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9FnrukU1in+njcoOtPe7Z1yYLqlGD6tBebrq/GFVRQ nico@Nasbert"
}

resource "local_file" "ssh_script" {
  content = templatefile("tpl/ssh.sh", {
    ip = hcloud_server.helloServer.ipv4_address
  })
  filename        = "bin/ssh"
  file_permission = "700"
  depends_on      = [local_file.known_hosts]
}

resource "local_file" "known_hosts" {
  content         = "${hcloud_server.helloServer.ipv4_address} ${tls_private_key.host.public_key_openssh}"
  filename        = "gen/known_hosts"
  file_permission = "644"
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    loginUser        = "devops"
    public_key_deniz = hcloud_ssh_key.loginDeniz.public_key
    public_key_nico  = hcloud_ssh_key.loginNico.public_key
    public_key_goik  = hcloud_ssh_key.loginGoik.public_key
    rootPassword     = random_password.root_password.result
    tls_private_key  = tls_private_key.host.private_key_pem
    tls_public_key   = tls_private_key.host.public_key_openssh
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
  user_data    = local_file.user_data.content
  depends_on   = [local_file.user_data]
}
