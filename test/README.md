# Test

This folder contains Terraform declarations for supporting resources to test GDM
deployment with KMS encrypted disk.

<!-- markdownlint-disable MD033 MD034 -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.23 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.4 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.7 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_external"></a> [external](#module\_external) | memes/multi-region-private-network/google | 3.1.0 |
| <a name="module_mgmt"></a> [mgmt](#module\_mgmt) | memes/multi-region-private-network/google | 3.1.0 |
| <a name="module_secret"></a> [secret](#module\_secret) | memes/secret-manager/google | 2.2.2 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.test_ext_ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.test_mgmt_ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_member.service_agent](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.keyring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_secret_manager_secret_version.secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [local_file.gdm_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.harness_json](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.ssh_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.ssh_privkey](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.ssh_pubkey](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_id.key_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_shuffle.zones](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_string.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [http_http.my_address](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"f5-google-bigip-kms"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-west1"` | no |
| <a name="input_test_cidrs"></a> [test\_cidrs](#input\_test\_cidrs) | n/a | `list(any)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_network"></a> [external\_network](#output\_external\_network) | n/a |
| <a name="output_external_subnet"></a> [external\_subnet](#output\_external\_subnet) | n/a |
| <a name="output_mgmt_network"></a> [mgmt\_network](#output\_mgmt\_network) | n/a |
| <a name="output_mgmt_subnet"></a> [mgmt\_subnet](#output\_mgmt\_subnet) | n/a |
| <a name="output_password"></a> [password](#output\_password) | n/a |
| <a name="output_ssh_config"></a> [ssh\_config](#output\_ssh\_config) | n/a |
| <a name="output_ssh_pubkey"></a> [ssh\_pubkey](#output\_ssh\_pubkey) | n/a |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable MD033 MD034 -->
