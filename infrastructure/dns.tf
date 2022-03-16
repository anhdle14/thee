resource "google_service_account" "cert_manager" {
  account_id   = "cert-manager"
  display_name = "Cert Manager"

  description = <<EOF
  DNS01 Challenge Provider via Cert Manager.
EOF
}

resource "google_project_iam_binding" "this" {
  project = data.google_project.this.project_id
  role    = "roles/dns.admin"

  members = [
    "serviceAccount:${google_service_account.cert_manager.email}"
  ]
}

resource "google_service_account_key" "this" {
  service_account_id = google_service_account.cert_manager.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "cert_manager" {
  content  = base64decode(google_service_account_key.this.private_key)
  filename = "${path.module}/anhdle14-thee.json"
}

module "dns_public_zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "4.1.0"

  project_id = data.google_project.this.project_id
  type       = "public"
  name       = replace(var.dns_domain, ".", "-")
  domain     = "${var.dns_domain}."
  labels     = local.labels

  recordsets = [
    {
      name = "*.int"
      type = "A"
      ttl  = 300
      records = [
        data.tailscale_device.this.addresses[0]
      ]
    },
    {
      name = "int"
      type = "A"
      ttl  = 300
      records = [
        data.tailscale_device.this.addresses[0]
      ]
    },
  ]
}
