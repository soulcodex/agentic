## Git Conventions

### Commit Format

Use Conventional Commits (https://www.conventionalcommits.org):

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `build`

- Summary is imperative, lowercase, no period, max 72 characters.
- Body wraps at 100 characters. Explain *why*, not *what*.
- Reference issue numbers in footer: `Closes #123`, `Refs #456`.

Examples:
```
feat(auth): add JWT refresh token rotation
fix(cart): prevent negative quantity on decrement
refactor(users): extract email validation to value object
test(orders): add edge case for zero-amount orders
```

### Branch Naming

```
<type>/<short-description>
```

- Use lowercase kebab-case.
- Keep descriptions short (3-5 words).
- Examples: `feat/jwt-refresh`, `fix/cart-negative-qty`, `chore/update-deps`

### Pull Requests

- Title follows commit format: `type(scope): summary`
- Description must include: what changed, why, how to test.
- PRs must pass CI before merge.
- Squash merge to keep history clean; preserve the PR title as the commit message.
- Delete the branch after merge.

### PR Workflow

- Always branch from an updated `main` for new work.
- Each logical change should result in a single PR ready for review.
- Keep PRs small and focused — one PR = one logical change.
- Avoid mixing unrelated changes to reduce review fatigue.
- Prefer completing and merging smaller PRs over accumulating large diffs.

### Tagging & Releases

- Use SemVer: `MAJOR.MINOR.PATCH`
- Annotated tags: `git tag -a v1.2.3 -m "Release v1.2.3"`
- Changelog is updated as part of every release commit.
