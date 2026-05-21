## Terraform Module Skeleton

```text
modules/
  {module_name}/
    README.md
    versions.tf
    providers.tf
    main.tf
    variables.tf
    outputs.tf
    examples/
      basic/
        main.tf
        terraform.tfvars.example
```

### Required File Intent

- `README.md`: module purpose, input/output tables, usage example.
- `versions.tf`: `terraform` and provider version constraints.
- `providers.tf`: provider configuration requirements and aliases contract.
  Child modules should declare requirements, not hardcode credentials/regions.
- `main.tf`: resource definitions and local composition only.
- `variables.tf`: typed inputs with descriptions and sensible defaults.
- `outputs.tf`: intentional public outputs, no secret leakage.
- `examples/basic/main.tf`: runnable consumer example for validation.

### Recommended `versions.tf` baseline

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```
