# Workflow

## New Features
When asked to build a new feature (not a simple fix or modification):
1. **Implementation plan** — describe what we will build, the scope, and key decisions. Wait for approval.
2. **Architecture plan** — define the modules, interfaces, and data flow. Wait for approval.
3. **Tasks** — break the approved architecture into small, independent tasks. Execute sequentially.

## Simple Changes
For bug fixes, small modifications, or refactors — just do the work directly. No plan needed.

# Global Rules

## Design
- Object-oriented structure with functional principles (immutability, single responsibility)
- Composition over inheritance
- Simplest solution that meets requirements

## Security
- Security is the top priority — never sacrifice it for speed or convenience
- Never hardcode secrets, API keys, tokens, or credentials in code
- Never commit `.env`, `.secrets`, or credential files
- Validate and sanitize all external input (user input, API responses, file content)
- Use parameterized queries, never string-interpolated SQL

## Git
- Always read AGENTS.md before committing to respect project-specific git rules
- Never add agents co-authored lines to commit messages
