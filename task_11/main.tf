# Define Hetzner cloud provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 1.0"
}

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

resource "tls_private_key" "host" {
  algorithm = "ED25519"
}

# Add the ssh keys
resource "hcloud_ssh_key" "loginDeniz" {
  name       = "deniz@LegionSlim7-Deniz"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHo157bpi8OVPIv9WPPfKlcWmCu+68E3Ii5nfjtarAU dg102@hdm-stuttgart.de"
}

resource "hcloud_ssh_key" "loginDenizWSL" {
  name       = "deniz@LegionSlim7-WSL-Ubuntu"
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

resource "hcloud_volume" "volume01" {
  name      = "volume1"
  location  = "nbg1"
  size      = 10
  automount = false
  format    = "xfs"
}

resource "local_file" "user_data" {
  content = templatefile("tpl/userData.yml", {
    loginUser           = "devops"
    volume_id           = hcloud_volume.volume01.id
    public_key_deniz    = hcloud_ssh_key.loginDeniz.public_key
    public_key_denizWSL = hcloud_ssh_key.loginDenizWSL.public_key
    public_key_nico     = hcloud_ssh_key.loginNico.public_key
    public_key_goik     = hcloud_ssh_key.loginGoik.public_key
    rootPassword        = random_password.root_password.result
    tls_private_key     = indent(4, tls_private_key.host.private_key_openssh)
    tls_public_key      = tls_private_key.host.public_key_openssh
  })
  filename = "gen/userData.yml"
}

resource "hcloud_network" "pNet" {
  name     = "Private network"
  ip_range = "10.0.0.0/8"
}
resource "hcloud_network_subnet" "pSubnet" {
  network_id   = hcloud_network.pNet.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}
resource "hcloud_network_route" "gateway" {
  network_id  = hcloud_network.pNet.id
  destination = "0.0.0.0/0"
  gateway     = "10.0.1.20"
}

resource "hcloud_server" "intern1" {
  name        = "intern1"
  image       = "debian-12"
  server_type = "cx22"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.loginDeniz.id, hcloud_ssh_key.loginDenizWSL.id, hcloud_ssh_key.loginNico.id, hcloud_ssh_key.loginGoik.id]
  user_data   = local_file.user_data.content
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.pNet.id
    ip         = "10.0.1.21"
  }
}

resource "hcloud_server" "intern2" {
  name        = "intern2"
  image       = "debian-12"
  server_type = "cx22"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.loginDeniz.id, hcloud_ssh_key.loginDenizWSL.id, hcloud_ssh_key.loginNico.id, hcloud_ssh_key.loginGoik.id]
  user_data   = local_file.user_data.content
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.pNet.id
    ip         = "10.0.1.22"
  }
}

# Create a server
resource "hcloud_server" "helloServer" {
  name         = "hello"
  image        = "debian-12"
  server_type  = "cx22"
  location     = "nbg1"
  firewall_ids = [hcloud_firewall.sshFw.id]
  ssh_keys     = [hcloud_ssh_key.loginDeniz.id, hcloud_ssh_key.loginDenizWSL.id, hcloud_ssh_key.loginNico.id, hcloud_ssh_key.loginGoik.id]
  user_data    = local_file.user_data.content
  network {
    network_id = hcloud_network.pNet.id
    ip         = "10.0.1.20"
  }
}

resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.volume01.id
  server_id = hcloud_server.helloServer.id
}






