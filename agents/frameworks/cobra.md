## Cobra CLI (Go)

### Command Structure

- One `rootCmd` per binary. All subcommands are composed via `rootCmd.AddCommand(subCmd)`.
- Define each command in its own file under `internal/cli/` or `cmd/`. Never put all commands in a single file.
- Use `cobra.Command.RunE` (not `Run`) so errors propagate properly. Call `cobra.CheckErr(err)` in `main()` as the single exit point.

```go
func main() {
    cobra.CheckErr(rootCmd.Execute())
}
```

### Persistent Setup

- Use `PersistentPreRunE` on `rootCmd` for shared initialization that must run before any subcommand: loading config, initialising the logger, opening a database connection.
- Avoid `init()` functions — they run at package load time and are hard to test or override.

### Flags & Configuration

- Bind Cobra flags to Viper with `viper.BindPFlag("key", cmd.Flags().Lookup("flag-name"))` so both CLI flags and environment variables work transparently.
- Environment variables are automatically read when you call `viper.AutomaticEnv()` and set the prefix with `viper.SetEnvPrefix("APP")`.
- Persistent flags (available to all subcommands): declare on `rootCmd.PersistentFlags()`.
- Local flags (specific to one command): declare on the subcommand's `Flags()`.

### Structured Output

- Support a global `--output` flag with values `json`, `table`, and `plain`.
- Implement an `output.Writer` interface (or equivalent) that accepts the flag value and dispatches to the correct renderer — never scatter `if output == "json"` checks through command logic.
- Use `github.com/jedib0t/go-pretty/v6/table` (or `text/tabwriter`) for table output; `encoding/json` for JSON.

### Testability

- Command functions must accept `io.Writer` arguments (or carry them on a struct) instead of writing directly to `os.Stdout`. This makes output capturable in tests.
- Do **not** call `os.Exit` anywhere except in `main()` via `cobra.CheckErr`. Commands return errors; only the top-level entry point exits.
- Test each command by constructing the `cobra.Command`, setting `SetOut`/`SetErr`, calling `Execute()`, and asserting the written output.

```go
func TestVersionCmd(t *testing.T) {
    buf := &bytes.Buffer{}
    rootCmd.SetOut(buf)
    rootCmd.SetArgs([]string{"version"})
    require.NoError(t, rootCmd.Execute())
    assert.Contains(t, buf.String(), "v1.")
}
```

### Error Handling

- Return errors from `RunE`; never print them directly and return nil.
- Use `fmt.Errorf("context: %w", err)` to wrap errors with context.
- For user-input validation errors, return a descriptive error — Cobra will print it along with usage.
- Suppress usage printing on runtime errors (not flag errors): `cmd.SilenceUsage = true` in `PersistentPreRunE` after validation passes.
