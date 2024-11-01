# Setup

The Terraform in this folder will be executed before creating resources and can
be used to setup service accounts, service principals, etc, that are used by the
inspec-* verifiers.

## Configuration

Create a local `terraform.tfvars` file that configures the testing project
constraints.

```hcl
# The GCP project identifier to use
project_id  = "my-gcp-project"

# The single Compute Engine region where the resources will be created
region = "us-west1"

# Optional source CIDRs that will be permitted to access BIG-IP management interface; empty set (default) will autodetect
# user's address.
admin_source_cidrs = [
  "100.101.102.103/32",
]
```

<!-- markdownlint-disable MD033 MD034 -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.4 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | memes/multi-region-private-network/google | 3.0.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_project_iam_member.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [local_file.harness_json](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.ssh_private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_pet.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [random_shuffle.zones](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_string.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [http_http.test_address](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project id. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Compute engine region where resources will be created. | `string` | n/a | yes |
| <a name="input_admin_source_cidrs"></a> [admin\_source\_cidrs](#input\_admin\_source\_cidrs) | CIDRs permitted to access BIG-IP admin. An empty/null set will use an autodetected CIDR of host. | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- markdownlint-enable MD033 MD034 -->
