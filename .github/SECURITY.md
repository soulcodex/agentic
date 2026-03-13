# Security Policy

## Supported Versions

Only the `main` branch is actively supported with security updates. We recommend always using the latest version from main.

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| other   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Private disclosure** — Do not open a public GitHub issue
2. **GitHub Security Advisories** — Use [GitHub's private vulnerability reporting](https://github.com/soulcodex/agentic/security/advisories/new)
3. **Email** — Alternatively, email security concerns to `info@soulcodex.es`

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Any suggested fixes (optional)

We aim to acknowledge reports within 48 hours and provide a timeline for fixes.

## Security Warnings

### No Code Execution from Untrusted Sources

This library generates and outputs shell scripts, configuration files, and executable code that may be run by AI agents in your projects.

**Do not:**
- Use fragments or profiles from untrusted sources
- Deploy this library to projects without reviewing the generated output
- Trust AI-generated code without human review

**Always:**
- Review generated `AGENTS.md` and vendor files before committing
- Run `just lint` and `just test` locally before deploying
- Audit the output in your project's `.agentic/` directory

## Best Practices

- Fork this library and review all fragments before deploying to production projects
- Use the `just compose --dry-run` option to preview generated content
- Keep your fork updated with the latest changes from upstream
