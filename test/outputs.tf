output "external_network" {
  value = module.external.self_link
}

output "external_subnet" {
  value = [for k, v in module.external.subnets_by_name : v.self_link][0]
}

output "mgmt_network" {
  value = module.mgmt.self_link
}

output "mgmt_subnet" {
  value = [for k, v in module.mgmt.subnets_by_name : v.self_link][0]
}

output "password" {
  value = random_string.password.result
}

output "ssh_pubkey" {
  value = trimspace(tls_private_key.ssh.public_key_openssh)
}

output "ssh_config" {
  value = abspath(local_file.ssh_config.filename)
}
