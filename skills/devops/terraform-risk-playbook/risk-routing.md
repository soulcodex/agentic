## Terraform Risk Routing

Classify the task before proposing changes.

| Risk category | Common symptoms | Mandatory guardrails | Primary handoff |
|---|---|---|---|
| Identity churn | `count` index reshuffle, renamed resources/modules, missing `moved` blocks | explain address migration path, avoid blind rename, validate zero unexpected destroy | `create-terraform-module` |
| Secret exposure | secrets in defaults, outputs, state, CI logs, `.tfvars` | do not rely on `sensitive = true` as state protection, prefer references/runtime lookup, check state/log exposure | `design-aws-terraform-iac` |
| Blast radius | oversized stacks, shared state, risky prod apply, unclear destroy impact | reviewed `plan -out`, explicit approval, split state if lifecycle differs | `terraform-infrastructure` |
| CI drift | local plan differs from CI, apply reruns plan, unpinned versions | pin runtime/providers, apply reviewed artifact, record execution-path assumptions | `terraform-infrastructure` |
| Compliance gaps | missing policy stage, weak approvals, no evidence retention | add policy/security checks and approval model where applicable | `design-aws-terraform-iac` |
| Testing blind spots | plan-only assertions for computed values, mock/real confusion, set indexing mistakes | choose `plan` vs `apply` tests intentionally, state confidence limits | `create-terraform-tests` |
| State corruption / recovery | stuck lock, backend migration, drift reconciliation | protect evidence, document rollback and recovery sequence before mutation | `terraform-infrastructure` |
| Provider upgrade risk | breaking provider bump, runtime bump mixed with functional changes | isolate upgrade diff, pin versions, validate migration notes | `create-terraform-module` |
| Provider lifecycle | removing provider with live state, orphaned resources, `removed` usage | require explicit state transition or removal plan | `terraform-infrastructure` |
| Provisioner misuse | `null_resource`, `local-exec`, `remote-exec` for durable workflows | treat as last resort, call out secret/logging risk and lifecycle drift | `create-terraform-module` |

Default validation expectations by risk tier:
- low: `terraform fmt -check -recursive`, `terraform validate`
- medium: add `terraform plan -out=tfplan` or `terraform test`
- high: reviewed plan artifact, approval gate, rollback notes, and any policy or
  security checks the repo already uses
