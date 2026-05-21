## Acceptance Checklist

Use these checks before module implementation begins.

- [ ] Architecture scope, non-goals, and assumptions are documented.
- [ ] AWS service selection includes rationale and known alternatives.
- [ ] Module boundaries and ownership are explicit.
- [ ] Remote state backend and locking strategy are documented (prefer S3
      lockfile; DynamoDB locking only for legacy compatibility).
- [ ] Environment/region strategy is documented with naming convention.
- [ ] CI plan/apply gate strategy includes manual approval for production.
- [ ] IAM baseline and encryption requirements are documented.
- [ ] Secret handling and state exposure risks are explicitly documented.
- [ ] Logging, metrics, and alerting ownership are documented.
- [ ] Rollback path and operational runbook entry points are identified.
- [ ] Cost visibility tags and budget guardrails are defined.
