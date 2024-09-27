terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

data "google_compute_zones" "zones" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

data "http" "test_address" {
  url = "https://checkip.amazonaws.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get local IP address."
    }
  }
}

resource "random_shuffle" "zones" {
  input = data.google_compute_zones.zones.names
}

resource "random_pet" "prefix" {
  length = 1
  keepers = {
    project = var.project_id
  }
}

resource "random_string" "password" {
  length           = 16
  upper            = true
  min_upper        = 1
  lower            = true
  min_lower        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "#@"
}

resource "google_service_account" "sa" {
  project      = var.project_id
  account_id   = format("%s-bigip", random_pet.prefix.id)
  display_name = format("f5-big-ip-fips-on-gcp test service account")
  description  = <<-EOD
A test service account for automated BIG-IP testing.
EOD
}

resource "google_project_iam_member" "sa" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ])
  project = var.project_id
  role    = each.key
  member  = google_service_account.sa.member
  depends_on = [
    google_service_account.sa,
  ]
}

# Create VPC network with a single subnet
module "vpc" {
  source      = "memes/multi-region-private-network/google"
  version     = "3.0.0"
  project_id  = var.project_id
  name        = format("%s-vpc", random_pet.prefix.id)
  description = format("BIG-IP FIPS testing VPC (%s)", random_pet.prefix.id)
  regions = [
    var.region,
  ]
  cidrs = {
    primary_ipv4_cidr          = "10.10.0.0/16"
    primary_ipv4_subnet_size   = 24
    primary_ipv4_subnet_offset = 0
    primary_ipv4_subnet_step   = 1
    primary_ipv6_cidr          = null
    secondaries                = null
  }
  options = {
    delete_default_routes = false
    flow_logs             = true
    ipv6_ula              = false
    mtu                   = 1460
    nat                   = false
    nat_logs              = true
    nat_tags              = null
    private_apis          = false
    restricted_apis       = false
    routing_mode          = "REGIONAL"
  }
}

# Grant access to management interface for SSH and HTTPS
resource "google_compute_firewall" "admin" {
  project       = var.project_id
  name          = format("%s-allow-admin", random_pet.prefix.id)
  network       = module.vpc.self_link
  description   = "BIG-IP administration on testing network"
  direction     = "INGRESS"
  source_ranges = coalescelist(var.admin_source_cidrs, [format("%s/32", trimspace(data.http.test_address.response_body))])
  target_service_accounts = [
    google_service_account.sa.email,
  ]
  allow {
    protocol = "tcp"
    ports = [
      22,
      8443,
    ]
  }
  depends_on = [
    module.vpc
  ]
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  filename        = format("%s/%s-id_rsa", path.module, random_pet.prefix.id)
  file_permission = "0600"
  content         = trimspace(tls_private_key.ssh.private_key_pem)

  depends_on = [
    tls_private_key.ssh,
  ]
}

resource "local_file" "harness_json" {
  filename = format("%s/harness.json", path.module)
  content = jsonencode({
    network              = format("%s-vpc", random_pet.prefix.id)
    password             = random_string.password.result
    project              = var.project_id
    region               = var.region
    service_account      = google_service_account.sa.email
    ssh_private_key_path = abspath(local_file.ssh_private_key.filename)
    ssh_public_key       = trimspace(tls_private_key.ssh.public_key_openssh)
    subnet               = module.vpc.subnets_by_region[var.region].name
  })
  depends_on = [
    google_service_account.sa,
    google_project_iam_member.sa,
    google_compute_firewall.admin,
    module.vpc,
    tls_private_key.ssh,
    local_file.ssh_private_key,
  ]
}
