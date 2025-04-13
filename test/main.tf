terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.23"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

data "http" "my_address" {
  url = "https://checkip.amazonaws.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get local IP address"
    }
  }
}

data "google_compute_zones" "zones" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

resource "random_shuffle" "zones" {
  input = data.google_compute_zones.zones.names
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
  override_special = "@#"
}

locals {
  test_cidrs = coalescelist(var.test_cidrs, [format("%s/32", trimspace(data.http.my_address.response_body))])
  labels = {
    identifier = var.name
    use-case   = "kms-test"
  }
}

resource "google_service_account" "sa" {
  project      = var.project_id
  account_id   = var.name
  display_name = "BIG-IP with KMS"
  description  = "Service account for BIG-IP with KMS disk encryption testing"
}

module "secret" {
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = format("%s-password", var.name)
  secret     = null
  accessors = [
    google_service_account.sa.member,
  ]
}

resource "google_secret_manager_secret_version" "secret" {
  secret      = module.secret.id
  secret_data = random_string.password.result
}

module "external" {
  source      = "memes/multi-region-private-network/google"
  version     = "3.1.0"
  project_id  = var.project_id
  name        = format("%s-external", var.name)
  description = "External test VPC network for automated BIG-IP testing"
  regions = [
    var.region,
  ]
  cidrs = {
    primary_ipv4_cidr          = "172.16.0.0/16"
    primary_ipv4_subnet_size   = 24
    primary_ipv4_subnet_offset = 0
    primary_ipv4_subnet_step   = 10
    primary_ipv6_cidr          = null
    secondaries                = null
  }
  options = {
    delete_default_routes = false
    restricted_apis       = false
    nat                   = false
    nat_tags              = []
    mtu                   = 1460
    routing_mode          = "REGIONAL"
    flow_logs             = false
    ipv6_ula              = false
    nat_logs              = false
    private_apis          = false
  }
}

module "mgmt" {
  source      = "memes/multi-region-private-network/google"
  version     = "3.1.0"
  project_id  = var.project_id
  name        = format("%s-mgmt", var.name)
  description = "Management VPC network for automated testing"
  regions = [
    var.region,
  ]
  cidrs = {
    primary_ipv4_cidr          = "172.17.0.0/16"
    primary_ipv4_subnet_size   = 24
    primary_ipv4_subnet_offset = 0
    primary_ipv4_subnet_step   = 10
    primary_ipv6_cidr          = null
    secondaries                = null
  }
  options = {
    delete_default_routes = false
    restricted_apis       = false
    nat                   = false
    nat_tags              = []
    mtu                   = 1460
    routing_mode          = "REGIONAL"
    flow_logs             = false
    ipv6_ula              = false
    nat_logs              = false
    private_apis          = false
  }
}

resource "google_compute_firewall" "test_ext_ingress" {
  project       = var.project_id
  name          = format("%s-allow-external-ingress", var.name)
  network       = module.external.self_link
  description   = "Allow tester access to BIG-IP on external VPC"
  direction     = "INGRESS"
  source_ranges = local.test_cidrs
  target_service_accounts = [
    google_service_account.sa.email,
  ]
  allow {
    protocol = "all"
  }
  depends_on = [
    module.external,
    google_service_account.sa,
  ]
}

resource "google_compute_firewall" "test_mgmt_ingress" {
  project       = var.project_id
  name          = format("%s-allow-mgmt-ingress", var.name)
  network       = module.mgmt.self_link
  description   = "Allow tester access to BIG-IP on management VPC"
  direction     = "INGRESS"
  source_ranges = local.test_cidrs
  target_service_accounts = [
    google_service_account.sa.email,
  ]
  allow {
    protocol = "all"
  }
  depends_on = [
    module.mgmt,
    google_service_account.sa,
  ]
}

resource "random_id" "key_id" {
  byte_length = 4
  prefix      = var.name
  keepers = {
    project_id = var.project_id
    name       = var.name
  }
}

# NOTE: key rings are never fully destroyed and names cannot be reused.
resource "google_kms_key_ring" "keyring" {
  project  = var.project_id
  name     = random_id.key_id.hex
  location = var.region
}

resource "google_kms_crypto_key" "key" {
  name     = format("%s-disk", var.name)
  key_ring = google_kms_key_ring.keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  labels   = var.labels
}

# Compute Engine service agent must have access to use the key in order to
resource "google_kms_crypto_key_iam_member" "service_agent" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:service-%s@compute-system.iam.gserviceaccount.com", data.google_project.project.number)
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_privkey" {
  filename        = format("%s/%s-ssh", path.module, var.name)
  file_permission = "0600"
  content         = tls_private_key.ssh.private_key_pem
}

resource "local_file" "ssh_pubkey" {
  filename        = format("%s/%s-ssh.pub", path.module, var.name)
  file_permission = "0600"
  content         = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "ssh_config" {
  filename = format("%s/%s-ssh-config", path.module, var.name)
  content  = <<-EOC
  Host *
  User admin
  	CheckHostIP no
  	IdentitiesOnly yes
  	IdentityFile ${abspath(local_file.ssh_privkey.filename)}
  	UserKnownHostsFile /dev/null
  	StrictHostKeyChecking no
  EOC
  depends_on = [
    tls_private_key.ssh,
  ]
}

resource "local_file" "gdm_config" {
  filename = format("%s/../%s-gdm-config.yaml", path.module, var.name)
  content = templatefile(format("%s/templates/gdm-v2-standalone-config.yaml", path.module), {
    runtime_init_url = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/2.0.3/f5-bigip-runtime-init-2.0.3-1.gz.run"
    runtime_init_config = templatefile(format("%s/templates/runtime-init-config.yaml", path.module), {
      password_secret_id = module.secret.secret_id
      ssh_pubkey         = trimspace(tls_private_key.ssh.public_key_openssh)
    })
    external_network = module.external.self_link
    external_subnet  = [for k, v in module.external.subnets_by_name : v.self_link][0]
    kms_key_name     = google_kms_crypto_key.key.id
    mgmt_network     = module.mgmt.self_link
    mgmt_subnet      = [for k, v in module.mgmt.subnets_by_name : v.self_link][0]
    name             = var.name
    sa               = google_service_account.sa.email
    labels           = jsonencode(local.labels)
    zone             = random_shuffle.zones.result[0]
  })

  depends_on = [
    random_shuffle.zones,
    random_string.password,
    tls_private_key.ssh,
  ]
}

resource "local_file" "user_data" {
  filename = format("%s/../%s-user-data.yaml", path.module, var.name)
  content = templatefile(format("%s/templates/cloud-config.yaml", path.module), {
    runtime_init_url       = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/2.0.3/f5-bigip-runtime-init-2.0.3-1.gz.run"
    runtime_init_sha256sum = "e38fabfee268d6b965a7c801ead7a5708e5766e349cfa6a19dd3add52018549a"
    runtime_init_config = templatefile(format("%s/templates/runtime-init-config.yaml", path.module), {
      password_secret_id = module.secret.secret_id
      ssh_pubkey         = trimspace(tls_private_key.ssh.public_key_openssh)
    })
  })

  depends_on = [
    random_string.password,
    tls_private_key.ssh,
  ]
}

# Create an attributes file for values that are shared between scenarios
resource "local_file" "harness_json" {
  filename = format("%s/harness.json", path.module)
  content = jsonencode({
    name        = var.name
    project_id  = var.project_id
    ssh_config  = abspath(local_file.ssh_config.filename)
    ssh_privkey = abspath(local_file.ssh_privkey.filename)
    user_data   = abspath(local_file.user_data.filename)
    labels      = local.labels
    zone        = random_shuffle.zones.result[0],
  })

  depends_on = [
    google_service_account.sa,
    module.external,
    module.mgmt,
    local_file.ssh_privkey,
    local_file.ssh_pubkey,
    local_file.ssh_config,
    google_compute_firewall.test_ext_ingress,
    google_compute_firewall.test_mgmt_ingress,
  ]
}
