## TypeScript

### Compiler Configuration

Always enable strict mode in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### Type System

- Prefer `type` aliases over `interface` for union types and computed types.
  Use `interface` for object shapes that may be extended (especially public APIs).
- Never use `any`. Use `unknown` for genuinely unknown values and narrow with guards.
- Avoid type assertions (`as Foo`) except at system boundaries with validation.
- Use discriminated unions for modeling state:
  ```typescript
  type Result<T> = { ok: true; value: T } | { ok: false; error: Error }
  ```
- Prefer `readonly` for all data that should not be mutated.
- Use template literal types for string-constrained values: `type EventName = `${string}.${string}``

### Domain Modeling Conventions

- Model value objects with immutable types/classes plus runtime validation.
- Keep aggregate state private; mutate through intentful methods only.
- Keep domain types isolated from framework/transport concerns.
- Use explicit `toPrimitives` / `fromSnapshot` mapping at boundaries.
- Mapping code is acceptable when contexts have different semantics.

### Naming Conventions

| Construct | Convention | Example |
|---|---|---|
| Variables, functions | camelCase | `getUserById` |
| Classes, interfaces, types | PascalCase | `UserRepository` |
| Enums | PascalCase (values: SCREAMING_SNAKE) | `Status.ACTIVE` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Files | kebab-case | `user-repository.ts` |
| Test files | `*.test.ts` or `*.spec.ts` | `user-repository.test.ts` |

### Module System

- Use ES module syntax everywhere in TS/JS (`import` / `export` only).
- Never introduce CommonJS syntax (`require`, `module.exports`, `exports.foo`) in TS/JS code.
- Use ESModules (`"module": "ESNext"` or `"NodeNext"`). Avoid CommonJS for new code.
- Avoid barrel files (`index.ts` re-exporting everything). They hurt tree-shaking and create
  circular dependency risks.
- Use absolute alias imports configured via `paths` in tsconfig for cross-directory references.
- Relative imports are only allowed for files in the same folder (`./foo`); avoid parent traversal
  (`../`, `../../..`) and other cross-directory relative imports.

### Error Handling

- Model expected errors as values, not exceptions:
  ```typescript
  // Return Result type for expected failures
  function parseAge(raw: string): Result<number> { ... }
  ```
- Reserve `throw` for truly exceptional/unexpected conditions (programming errors, I/O failures).
- Never `catch` an error and silently swallow it. At minimum, log it.
- Use custom error classes with typed properties for domain errors.

### Boundary Validation and Webhooks

- Validate all external payloads (HTTP, webhook, queue) with schemas at the edge.
- Zod is a valid and recommended schema/validation option for TypeScript-first codebases.
- Keep schema versions explicit and synchronized with handler behavior.
- For webhooks, enforce signature verification, replay-window checks, and idempotency keys.
- Keep authorization checks in application handlers/services, not domain models.

### Code Style

- Use `pnpm` as the package manager.
- Format with Prettier (`.prettierrc` in repo root); lint with ESLint (flat config `eslint.config.ts`).
- Prefer `const` over `let`; never use `var`.
- Prefer named exports over default exports for better refactoring support.
- Keep functions small (fits on a screen). Extract when logic becomes layered.
- Prefer dependency injection/composition in the app layer; avoid global singletons.
