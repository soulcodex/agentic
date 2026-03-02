## Typer CLI (Python)

### Defining Commands

- Type annotations are the CLI contract. Typer derives argument names, types, and help text from function signatures — never add manual argument parsing.
- Use `@app.command()` for leaf commands. Compose sub-applications with `app.add_typer(sub_app, name="sub")`.
- Each command lives in its own module under `src/<package>/cli/`. Register all commands in a top-level `cli/app.py` that creates the root `typer.Typer()` instance.

```python
import typer

app = typer.Typer()

@app.command()
def deploy(
    env: str = typer.Argument(..., help="Target environment"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Preview changes"),
) -> None:
    ...
```

### Options & Environment Variables

- Back every important option with an environment variable using `typer.Option(envvar="APP_FOO")`.
- Provide sensible defaults so the CLI is usable without memorising all env vars.
- Group related options by creating a reusable `typer.Option` factory or shared callback.

### Output & Formatting

- Use `rich` for all structured output: tables (`rich.table.Table`), panels (`rich.panel.Panel`), progress bars (`rich.progress`), and syntax-highlighted code.
- Use `typer.echo()` only for single-line, unformatted text (e.g., simple confirmations). Prefer `rich.print()` for anything styled.
- Never mix `print()` with `rich` — it bypasses the rich console and breaks colour/width calculations.

### Validation & Error Handling

- Use `callback=` parameters on `typer.Option`/`typer.Argument` for inline validation:
  ```python
  def validate_port(value: int) -> int:
      if not (1 <= value <= 65535):
          raise typer.BadParameter(f"{value} is not a valid port number")
      return value
  ```
- Raise `typer.BadParameter` for user-input errors (Typer formats and exits cleanly).
- Raise `typer.Abort()` to cancel an interactive prompt or operation without an error message.
- Raise `typer.Exit(code=1)` only for non-exception exits; prefer returning from `RunE`-equivalent patterns.

### Testing

- Always test via `typer.testing.CliRunner` — never `subprocess.run` or direct function calls.
- `runner.invoke(app, ["cmd", "--flag", "value"])` returns a `Result` with `.output`, `.exit_code`, and `.exception`.
- Assert `.exit_code == 0` for success paths; assert specific output strings; assert `.exit_code != 0` for error paths.

```python
from typer.testing import CliRunner
from myapp.cli.app import app

runner = CliRunner()

def test_deploy_dry_run():
    result = runner.invoke(app, ["deploy", "staging", "--dry-run"])
    assert result.exit_code == 0
    assert "Preview" in result.output
```

### Async Commands

- Typer does not natively support `async def` commands. Wrap async logic with `asyncio.run()` inside a sync command function.
- Extract the async core into a separate function in the application layer and call it from the CLI command.
