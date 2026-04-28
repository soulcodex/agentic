# Workflow Checklist

1. Parse issue input from `new-gh-issue: ...`
2. Read issue and comments
3. Rebase main and create issue-scoped branch
4. Reviewer pre-analysis
5. Worker implementation
6. Required validation (`just lint`, plus `just index` / `just test` as needed)
7. Commit and push
8. PR creation with non-empty body verification
