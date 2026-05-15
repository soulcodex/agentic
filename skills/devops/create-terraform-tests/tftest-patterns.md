## Terraform Test Patterns

Suggested module test layout:

```text
modules/
  {module_name}/
    tests/
      basic.tftest.hcl
      validation.tftest.hcl
      security.tftest.hcl
```

### `basic.tftest.hcl`

Use for baseline resource creation and output checks.

### `validation.tftest.hcl`

Use for negative-path assertions (invalid CIDR, missing required input,
unsupported enum value).

### `security.tftest.hcl`

Use for controls such as:
- encryption enabled
- public access blocked
- retention/lifecycle policy defaults

### Pattern Guidance

- Prefer focused assertions over snapshot-style bulk checks.
- Keep fixtures minimal and deterministic.
- Make test names reflect intended risk (`s3_blocks_public_access`).
- Separate test data from secrets; never hardcode credentials.
