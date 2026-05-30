# Python Code Review Checklist

Extends the generic checklist. Apply every item to Python-specific concerns.

## Type Annotations

- [ ] All public function signatures have type annotations
  *Ref: [PEP 484 — Type Hints](https://peps.python.org/pep-0484/)*
- [ ] `from __future__ import annotations` used where forward references are needed
  *Ref: [PEP 563 — Postponed Evaluation of Annotations](https://peps.python.org/pep-0563/)*
- [ ] No `# type: ignore` without an inline comment explaining why
  *Ref: [mypy — Silencing errors](https://mypy.readthedocs.io/en/stable/common_issues.html#spurious-errors-and-locally-silencing-the-checker)*
- [ ] `mypy --strict` passes (or project-declared mypy config passes) in CI
  *Ref: [mypy strict mode](https://mypy.readthedocs.io/en/stable/command_line.html#cmdoption-mypy-strict)*

## Common Pitfalls

- [ ] No mutable default arguments: `def foo(items=[])` creates a shared mutable default
  *Ref: [Python Docs — Default argument values](https://docs.python.org/3/faq/programming.html#why-are-default-values-shared-between-objects)*
- [ ] No bare `except:` or `except Exception:` without re-raising or structured logging
  *Ref: [PEP 8 — Programming Recommendations](https://peps.python.org/pep-0008/#programming-recommendations)*
- [ ] No `contextlib.suppress` without an inline comment explaining why the error is intentionally ignored
  *Ref: [contextlib.suppress docs](https://docs.python.org/3/library/contextlib.html#contextlib.suppress)*
- [ ] No implicit string concatenation across lines (silent `O(n²)` string builds)

## Async and Concurrency

- [ ] No blocking I/O (`requests`, `open()`, `time.sleep()`) inside `async def` coroutines
  *Ref: [asyncio docs — Coroutines and Tasks](https://docs.python.org/3/library/asyncio-task.html)*
- [ ] Async HTTP calls use `httpx.AsyncClient` or `aiohttp`, not `requests`
  *Ref: [HTTPX async docs](https://www.python-httpx.org/async/)*
- [ ] `asyncio.gather()` used correctly — exceptions in subtasks are handled, not silently dropped
  *Ref: [asyncio.gather docs](https://docs.python.org/3/library/asyncio-task.html#asyncio.gather)*
- [ ] Thread safety: compound operations on `dict`/`list` (check-then-act, iterate-and-modify) use `threading.Lock`
  *Ref: [Python GIL — glossary](https://docs.python.org/3/glossary.html#term-global-interpreter-lock); [threading.Lock docs](https://docs.python.org/3/library/threading.html#lock-objects)*

## Domain Modeling

- [ ] Domain exceptions defined in `domain/exceptions.py`, not generic `Exception` subclasses
- [ ] Raw `dict` not used for domain objects — use `dataclass`, Pydantic model, or typed NamedTuple
  *Ref: [PEP 557 — Data Classes](https://peps.python.org/pep-0557/)*
- [ ] No primitive obsession: domain IDs use `TypeAlias` or `NewType`, not raw `str`/`int`
  *Ref: [PEP 613 — TypeAlias](https://peps.python.org/pep-0613/)*

## Code Style

- [ ] `pathlib.Path` used instead of `os.path` for all file operations
  *Ref: [PEP 428 — pathlib](https://peps.python.org/pep-0428/)*
- [ ] No `os.path` calls in new code
- [ ] Ruff linting passes with the project's configured rule set
  *Ref: [Ruff docs](https://docs.astral.sh/ruff/)*
- [ ] No global mutable state (module-level variables that are mutated at runtime)