# Workflow Checklist

1. Parse issue input from `new-gh-issue: ...`
2. Read issue and comments
3. Rebase main and create issue-scoped branch
4. Reviewer pre-analysis
5. Worker implementation
6. Reviewer validation gate
6.1 If findings exist, acknowledge developer
6.2 If in-scope and required, send mitigation plan to worker
6.3 Re-review after fixes
6.4 Stop after 3 automatic iterations and request explicit developer direction
7. Required validation (`just lint`, plus `just index` / `just test` as needed)
8. Commit and push
9. PR creation with non-empty body verification
