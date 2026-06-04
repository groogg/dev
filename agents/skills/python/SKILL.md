---
name: python
description: Python 3.12+ conventions, preferred libraries, code style, and organization rules. Use when writing or reviewing Python code.
---

# Python Skill

Python 3.12+ standards for this project. Apply these rules to all Python code.

## Libraries

Check if `kickstart` offers utilities to solve the problem first. Use it **when applicable** to avoid reinventing the wheel. If incomplete or missing features, supplement with other tools or custom implementations.

| Purpose | Use | Never |
|---|---|---|
| Paths (local) | `pathlib` | string concatenation |
| Paths (cloud/remote) | `universal_pathlib` (`upath`) | |
| CLI | `typer` | argparse, click |
| DataFrames | `polars` with `LazyFrame` | pandas |
| Serialization/models | `pydantic` | |
| Config | `pydantic-settings` with env vars, validated at startup | |
| Logging | `loguru` (DEBUG/INFO/WARNING/ERROR with structured context) | |
| REST APIs | `fastapi` with pydantic request/response models | |
| Package management | `uv` with pinned versions | |
| Testing | `pytest` | |

## Style & Design

### Naming & Annotations
- Full type annotations on all functions, parameters, return values, and class attributes. No exceptions.
- Unambiguous names
- Use names that say what the function does
- No docstrings unless the function is genuinely non-obvious or intended for outside use (e.g., SDK)
- No comments unless the logic is non-obvious

### Types
- Use `Literal` for small value sets local to a signature (e.g., `direction: Literal["asc", "desc"]`)
- Use `StrEnum` for domain concepts referenced across modules or needing runtime iteration/validation — if you'd import it from another file, it should be a `StrEnum`
- No magic strings

### Errors
- Explicit exception types, never bare `except`, never silently pass
- Custom exception classes for domain errors

### Visibility
- Prefix all non-public class attributes with `_`
- Use `@property` only for necessary public access
- Prefix private methods with `_`

### Functions
- Small number of arguments. No argument is best, followed by one, two, and three. More than three should be avoided.
- Each function should do exactly one thing. Avoid flag or selector arguments — they indicate a function does more than one thing.
- Functions should either have side-effects or return values — very rarely both.
- Functions should ideally return only one value or object.
- Functions should descend only one level of abstraction as you follow the call chain.
- Do not use output arguments (mutable arguments modified in the called function). If a function must change state, have it change the state of the object it is called on.
- When it does not complicate things, prefer not to pass callable functions as arguments.
- Design functions to receive dependencies as arguments rather than instantiating them internally — this avoids mocking. When a dependency has an obvious default, use `None` and instantiate inside only if not provided:

```python
def fetch_records(
    filters: RecordFilter,
    client: HttpClient | None = None,
) -> list[Record]:
    client = client or HttpClient()
    ...
```

## Organization

- Organize by business domain (e.g., `charging/`, `anomalies/`)
- Reusable technical components in `utils/`
- No mixing concerns across domains

## Security

- All secrets via environment variables or `pydantic-settings`
- No `eval()`, `exec()`, or `subprocess` with unsanitized input
