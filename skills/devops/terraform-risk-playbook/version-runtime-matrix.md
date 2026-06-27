## Terraform and OpenTofu Version Guard Matrix

Use this matrix before suggesting version-sensitive features.

| Feature or pattern | Minimum Terraform version | Guidance |
|---|---|---|
| `moved` blocks | 1.1+ | use for safe address refactors instead of rename-only edits |
| `nullable = false` | 1.1+ | prevent silent `null` override of defaults |
| `optional()` with typed defaults | 1.3+ | prefer over loose `map(any)` interfaces |
| `import` blocks | 1.5+ | prefer declarative import flow when runtime supports it |
| `check` blocks | 1.5+ | use for runtime assertions where applicable |
| native `terraform test` | 1.6+ | prefer for module-level validation before heavier integration tests |
| mock providers | 1.7+ | useful for low-cost unit-style tests; still keep real-cloud validation for final confidence |
| `removed` blocks | 1.7+ | use for explicit lifecycle/removal transitions |
| cross-variable validation | 1.9+ | call out runtime floor before referencing other vars in `validation` |
| S3 `use_lockfile` | 1.10+ | preferred default for new S3 backends; older runtimes may still need DynamoDB locking |
| `write_only` arguments | 1.11+ | use when supported to keep secret values out of state |

Runtime assumptions:
- if the user does not specify runtime, state whether guidance assumes
  `terraform` or `tofu`
- if the runtime is OpenTofu and the feature is newer or provider-specific,
  instruct the user to verify exact feature parity before adoption
- if runtime and backend are both unknown, assume the lowest safe guidance path
  and disclose that assumption explicitly
