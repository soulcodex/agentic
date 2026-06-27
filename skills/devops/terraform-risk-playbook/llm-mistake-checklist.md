## Terraform LLM Mistake Checklist

Check these before finalizing Terraform or OpenTofu guidance.

- Do not use list index as long-lived identity if item order can change.
  Prefer `for_each` when address stability matters.
- Do not rename resources/modules textually without discussing `moved` blocks or
  equivalent migration steps.
- Do not treat `sensitive = true` as state protection. It masks display only.
- Do not suggest storing secrets in defaults, committed `.tfvars`, outputs, or
  long-lived CI artifacts.
- Do not mix provider/runtime upgrades with functional changes unless the user
  explicitly asks for both and the upgrade risk is called out.
- Do not recommend re-running `plan` inside apply jobs for production-impacting
  workflows when a reviewed artifact should be applied.
- Do not assume computed values are available in plan-time tests; switch to
  apply-capable tests when needed.
- Do not index set-type nested blocks with `[0]`; use expressions that do not
  depend on set ordering.
- Do not recommend `terraform destroy` without `plan -destroy`, explicit review,
  and rollback notes.
- Do not recommend shared production and non-production state or local state for
  team or production workflows.
