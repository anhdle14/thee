locals {
  labels = merge(var.labels, {
    "managed-by" = "terraform"
  })
}

################################################################################
data "google_project" "this" {}

resource "google_project_service" "dns" {
  project = data.google_project.this.project_id
  service = "dns.googleapis.com"
}

################################################################################
resource "tailscale_dns_nameservers" "this" {
  nameservers = flatten([
    "1.1.1.1",
    module.dns_public_zone.name_servers
  ])
}

resource "tailscale_dns_preferences" "this" {
  magic_dns = true
}
